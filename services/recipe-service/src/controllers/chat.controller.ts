import axios from 'axios';
import { Response } from 'express';
import { Readable } from 'stream';
import { StringDecoder } from 'string_decoder';
import { z } from 'zod';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import prisma from '../services/prismaClient';
import logger from '../services/logger';

const chatRequestSchema = z
  .object({
    prompt: z.string().min(1),
    page_context: z.enum(['home', 'recipe_detail']),
    session_id: z.string().min(1),
    recipe_id: z.string().min(1).optional(),
  })
  .superRefine((value, ctx) => {
    if (value.page_context === 'recipe_detail' && !value.recipe_id) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['recipe_id'],
        message: 'recipe_id is required when page_context is recipe_detail',
      });
    }
  });

const normalizeIngredientName = (value: string): string => value.trim().toLowerCase();

const ensureUser = async (authId: string) => {
  const existingUser = await prisma.user.findUnique({
    where: { authId },
    select: { id: true },
  });

  if (existingUser) {
    return existingUser;
  }

  return prisma.user.create({
    data: { authId },
    select: { id: true },
  });
};

const ensureIngredient = async (ingredientName: string) => {
  const normalizedName = normalizeIngredientName(ingredientName);

  return prisma.ingredient.upsert({
    where: { name: normalizedName },
    update: {},
    create: { name: normalizedName },
    select: {
      id: true,
      name: true,
      icon: true,
    },
  });
};

interface RecipeContextPayload {
  id: string;
  title: string;
  instructions: string[];
  ingredients: Array<{
    amount?: string | null;
    ingredient: {
      name: string;
    };
  }>;
}

const AI_SERVICE_URL_RAW = (process.env.AI_SERVICE_URL ?? 'http://127.0.0.1:8000').replace(/\/$/, '');
const AI_SERVICE_BASE_URL = AI_SERVICE_URL_RAW.replace(/\/api$/i, '');
const AI_SERVICE_API_BASE_URL = `${AI_SERVICE_BASE_URL}/api`;

const buildRecipeContext = (recipe: RecipeContextPayload): string => {
  const ingredients = recipe.ingredients.length
    ? recipe.ingredients
      .map(({ ingredient, amount }) => {
        const normalizedAmount = typeof amount === 'string' ? amount.trim() : '';
        return normalizedAmount ? `- ${ingredient.name} (${normalizedAmount})` : `- ${ingredient.name}`;
      })
      .join('\n')
    : '- No ingredients listed';

  const instructions = recipe.instructions.length
    ? recipe.instructions.map((step, index) => `${index + 1}. ${step}`).join('\n')
    : '- No instruction steps listed';

  return [
    `Recipe title: ${recipe.title}`,
    'Ingredients:',
    ingredients,
    'Instructions:',
    instructions,
  ].join('\n');
};

const loadRecipeContext = async (
  req: AuthenticatedRequest,
  recipeId: string,
): Promise<string | null> => {
  if (!req.user?.id) {
    return null;
  }

  const recipe = await prisma.recipe.findFirst({
    where: {
      id: recipeId,
      author: {
        authId: req.user.id,
      },
    },
    include: {
      ingredients: {
        include: {
          ingredient: true,
        },
      },
    },
  });

  if (!recipe) {
    return null;
  }

  return buildRecipeContext(recipe as RecipeContextPayload);
};

const getAxiosErrorMessage = (error: unknown): string => {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data;

    if (typeof data === 'string' && data.trim().length > 0) {
      return data;
    }

    if (data && typeof data === 'object' && 'detail' in data) {
      const detail = (data as { detail?: unknown }).detail;
      if (typeof detail === 'string' && detail.trim().length > 0) {
        return detail;
      }
    }

    return error.message;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return 'Unknown error';
};

const getAxiosStatusCode = (error: unknown, fallbackStatus = 500): number => {
  if (axios.isAxiosError(error) && error.response?.status) {
    return error.response.status;
  }

  return fallbackStatus;
};

const getFriendlyAiErrorMessage = (
  rawMessage: string,
): string => {
  const normalized = rawMessage.toLowerCase();
  const isRateLimited =
    normalized.includes('resource_exhausted')
    || normalized.includes('quota')
    || normalized.includes('rate limit')
    || normalized.includes('429');

  if (isRateLimited) {
    return 'Rate limit reached, please try again shortly.';
  }

  return 'AI service is temporarily unavailable. Please try again.';
};

const getUserFacingAxiosErrorMessage = (error: unknown): string => {
  const rawMessage = getAxiosErrorMessage(error);
  return getFriendlyAiErrorMessage(rawMessage);
};

const logAxiosFailure = (label: string, error: unknown): void => {
  logger.error(
    `${label} | status=${getAxiosStatusCode(error)} | detail=${getAxiosErrorMessage(error)}`,
  );
};

// ----------------------------------------------------------------------
// Express Gateway Endpoint
// ----------------------------------------------------------------------

export const streamChat = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  const parsed = chatRequestSchema.safeParse(req.body);

  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  if (!req.user?.id) {
    res.status(401).json({ error: 'Unauthorized' });
    return;
  }

  const { prompt, page_context, session_id, recipe_id } = parsed.data;

  let recipeContext: string | null = null;
  if (page_context === 'recipe_detail' && recipe_id) {
    try {
      recipeContext = await loadRecipeContext(req, recipe_id);
    } catch (error) {
      console.error('Failed to load recipe context', { recipeId: recipe_id, error });
      res.status(500).json({ error: 'Failed to load recipe context' });
      return;
    }

    if (!recipeContext) {
      res.status(404).json({ error: 'Recipe not found' });
      return;
    }
  }

  try {
    const user = await ensureUser(req.user.id);

    const isRecipeDetail = page_context === 'recipe_detail' && typeof recipe_id === 'string' && recipe_id.trim().length > 0;
    const currentRecipeId = isRecipeDetail ? recipe_id.trim() : null;

    // 1. Fetch the last 10 messages (5 Q&As) to send to AI Agent as context (matching the current context)
    const historyMessages = await prisma.chefChatMessage.findMany({
      where: {
        userId: user.id,
        recipeId: currentRecipeId,
      },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    const formattedHistory = historyMessages.reverse().map((msg) => ({
      role: msg.isAi ? 'model' : 'user',
      content: msg.content,
    }));

    // 2. Save the current user prompt to DB linked to context
    await prisma.chefChatMessage.create({
      data: {
        userId: user.id,
        content: prompt,
        isAi: false,
        recipeId: currentRecipeId,
      },
    });

    logger.info('Forwarding chat request to unified AI Agent');

    const aiResponse = await axios.post(
      `${AI_SERVICE_API_BASE_URL}/agent/chat`,
      {
        prompt,
        page_context,
        session_id,
        recipe_context: recipeContext,
        recipe_id,
        history: formattedHistory,
      },
      {
        headers: {
          'Content-Type': 'application/json',
          'Authorization': req.headers.authorization || '',
          'X-App-Secret': process.env.INTERNAL_APP_SECRET || '',
        },
        responseType: 'stream',
        timeout: 0,
      }
    );

    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
      'X-Accel-Buffering': 'no',
    });

    const upstreamStream = aiResponse.data as Readable;
    upstreamStream.pipe(res);

    // 3. Track and accumulate the AI response stream to save to DB
    const decoder = new StringDecoder('utf-8');
    let accumulatedAnswer = '';
    let streamBuffer = '';

    upstreamStream.on('data', async (chunk: Buffer) => {
      streamBuffer += decoder.write(chunk);
      let lineEnd;
      while ((lineEnd = streamBuffer.indexOf('\n')) !== -1) {
        const line = streamBuffer.slice(0, lineEnd).trim();
        streamBuffer = streamBuffer.slice(lineEnd + 1);
        if (line.startsWith('data:')) {
          const dataStr = line.slice(5).trim();
          if (dataStr === '[DONE]') {
            continue;
          }
          try {
            const parsedChunk = JSON.parse(dataStr);
            if (parsedChunk.type === 'text' && typeof parsedChunk.delta === 'string') {
              accumulatedAnswer += parsedChunk.delta;
            } else if (parsedChunk.type === 'recipeCreated' && parsedChunk.recipe) {
              await prisma.chefChatMessage.create({
                data: {
                  userId: user.id,
                  content: parsedChunk.recipe.title || 'Your Recipe',
                  isAi: true,
                  messageType: 'recipePreview',
                  metadata: parsedChunk.recipe,
                  recipeId: currentRecipeId,
                },
              });
            } else if (parsedChunk.type === 'searchResults' && Array.isArray(parsedChunk.recipes)) {
              await prisma.chefChatMessage.create({
                data: {
                  userId: user.id,
                  content: '',
                  isAi: true,
                  messageType: 'searchResults',
                  metadata: { recipes: parsedChunk.recipes },
                  recipeId: currentRecipeId,
                },
              });
            } else if (parsedChunk.type === 'shoppingListAdded' && Array.isArray(parsedChunk.items)) {
              await prisma.chefChatMessage.create({
                data: {
                  userId: user.id,
                  content: '',
                  isAi: true,
                  messageType: 'shoppingListAdded',
                  metadata: { items: parsedChunk.items },
                  recipeId: currentRecipeId,
                },
              });
            } else if (parsedChunk.type === 'metadata') {
              const swaps = parsedChunk.suggested_swaps ||
                parsedChunk.healthier_swaps ||
                parsedChunk.substitutions ||
                parsedChunk.swaps;
              if (Array.isArray(swaps) && swaps.length > 0) {
                await prisma.chefChatMessage.create({
                  data: {
                    userId: user.id,
                    content: 'Suggested Substitutions',
                    isAi: true,
                    messageType: 'swapSummary',
                    metadata: { swaps },
                    recipeId: currentRecipeId,
                  },
                });
              }
            }
          } catch (e) {
            // Ignore incomplete lines
          }
        }
      }
    });

    let saved = false;
    const saveAnswer = async () => {
      if (saved) return;
      saved = true;
      const cleanAnswer = accumulatedAnswer.trim();
      if (cleanAnswer) {
        try {
          await prisma.chefChatMessage.create({
            data: {
              userId: user.id,
              content: cleanAnswer,
              isAi: true,
              recipeId: currentRecipeId,
            },
          });
        } catch (err) {
          logger.error('Failed to save AI response:', err);
        }
      }
    };

    upstreamStream.on('end', saveAnswer);

    req.on('close', () => {
      saveAnswer();
      if (!upstreamStream.destroyed) {
        upstreamStream.destroy();
      }
    });

  } catch (error: any) {
    logAxiosFailure('AI Agent request failed', error);
    const statusCode = getAxiosStatusCode(error);
    res.status(statusCode).json({
      error: getUserFacingAxiosErrorMessage(error),
    });
  }
};

export const getChatHistory = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { pageContext, recipeId } = req.query;

    const user = await ensureUser(req.user.id);

    const isRecipeDetail = pageContext === 'recipe_detail' && typeof recipeId === 'string' && recipeId.trim().length > 0;
    const currentRecipeId = isRecipeDetail ? recipeId.trim() : null;

    const history = await prisma.chefChatMessage.findMany({
      where: {
        userId: user.id,
        recipeId: currentRecipeId,
      },
      orderBy: {
        createdAt: 'desc',
      },
      take: 20,
    });

    res.json(history.reverse());
  } catch (error) {
    console.error('Failed to fetch chef chat history', error);
    res.status(500).json({ error: 'Failed to fetch chef chat history' });
  }
};

// ----------------------------------------------------------------------
// Internal Callback Endpoints
// ----------------------------------------------------------------------

export const internalSearchRecipes = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { embedding } = req.body;
    if (!Array.isArray(embedding) || embedding.length === 0) {
      res.status(400).json({ error: 'Invalid or missing embedding array' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { authId: req.user.id },
      select: { id: true },
    });

    if (!user) {
      res.json([]);
      return;
    }


    const vectorLiteral = `[${embedding.map((v: number) => Number(v).toString()).join(',')}]`;
    const SEARCH_MAX_DISTANCE = Number(process.env.SEARCH_MAX_DISTANCE ?? '0.5');

    const searchResults = await prisma.$queryRaw<Array<{ id: string; distance: number }>>`
      SELECT "id", ("embedding" <=> CAST(${vectorLiteral} AS vector)) AS "distance"
      FROM "Recipe"
      WHERE "embedding" IS NOT NULL
        AND "authorId" = ${user.id}
        AND ("embedding" <=> CAST(${vectorLiteral} AS vector)) <= ${SEARCH_MAX_DISTANCE}
      ORDER BY "embedding" <=> CAST(${vectorLiteral} AS vector)
      LIMIT 3
    `;

    const recipeIds = searchResults.map((result) => result.id);
    let recipes: any[] = [];

    if (recipeIds.length > 0) {
      recipes = await prisma.recipe.findMany({
        where: {
          id: {
            in: recipeIds,
          },
        },
        include: {
          ingredients: {
            include: {
              ingredient: true,
            },
          },
        },
      });

      const recipeById = new Map(recipes.map((recipe) => [recipe.id, recipe]));
      recipes = recipeIds
        .map((id) => recipeById.get(id))
        .filter((recipe): recipe is NonNullable<typeof recipe> => Boolean(recipe));
    }

    const recipeDTOs = recipes.map((recipe) => ({
      id: recipe.id,
      title: recipe.title,
      healthScore: recipe.healthScore,
      imageUrl: recipe.imageUrl || 'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=300&h=200',
      ingredients: recipe.ingredients?.map((ri: any) => ri.ingredient.name) || [],
    }));

    res.json(recipeDTOs);
  } catch (error) {
    console.error('Internal recipes search failed', error);
    res.status(500).json({ error: 'Internal recipes search failed' });
  }
};

export const internalAddToShoppingList = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { items } = req.body;
    if (!Array.isArray(items)) {
      res.status(400).json({ error: 'Items array is required' });
      return;
    }

    const user = await ensureUser(req.user.id);
    const addedItems: string[] = [];

    if (items.length > 0) {
      const prismaAny = prisma as any;
      for (const item of items) {
        const name = typeof item === 'string' ? item : item.name;
        const amount = typeof item === 'string' ? null : item.amount || null;

        const normalizedName = name.trim().toLowerCase();
        if (!normalizedName) {
          continue;
        }

        const ingredient = await ensureIngredient(normalizedName);

        const existing = await prismaAny.shoppingListItem.findUnique({
          where: {
            userId_ingredientId: {
              userId: user.id,
              ingredientId: ingredient.id,
            },
          },
        });

        if (!existing) {
          await prismaAny.shoppingListItem.create({
            data: {
              userId: user.id,
              ingredientId: ingredient.id,
              checked: false,
              amount: amount || null,
            },
          });
        } else if (amount) {
          await prismaAny.shoppingListItem.update({
            where: { id: existing.id },
            data: { amount },
          });
        }
        addedItems.push(amount ? `${amount} ${name}` : name);
      }
    }

    res.json(addedItems);
  } catch (error) {
    console.error('Internal add to shopping list failed', error);
    res.status(500).json({ error: 'Internal add to shopping list failed' });
  }
};

export const internalAddRecipeToShoppingList = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { recipeName, recipeId } = req.body;
    let itemsToAdd: Array<{ name: string; amount: string | null }> = [];

    if (recipeId) {
      const recipe = await prisma.recipe.findFirst({
        where: {
          id: recipeId,
          author: { authId: req.user.id },
        },
        include: {
          ingredients: {
            include: {
              ingredient: true,
            },
          },
        },
      });
      if (recipe) {
        itemsToAdd = recipe.ingredients.map((ri) => ({
          name: ri.ingredient.name,
          amount: ri.amount || null,
        }));
      }
    } else if (recipeName) {
      const recipe = await prisma.recipe.findFirst({
        where: {
          title: { contains: recipeName, mode: 'insensitive' },
          author: { authId: req.user.id },
        },
        include: {
          ingredients: {
            include: {
              ingredient: true,
            },
          },
        },
      });
      if (recipe) {
        itemsToAdd = recipe.ingredients.map((ri) => ({
          name: ri.ingredient.name,
          amount: ri.amount || null,
        }));
      } else {
        res.status(404).json({ error: 'Recipe not found' });
        return;
      }
    }

    const user = await ensureUser(req.user.id);
    const addedItems: string[] = [];

    if (itemsToAdd.length > 0) {
      const prismaAny = prisma as any;
      for (const item of itemsToAdd) {
        const normalizedName = item.name.trim().toLowerCase();
        if (!normalizedName) {
          continue;
        }

        const ingredient = await ensureIngredient(normalizedName);

        const existing = await prismaAny.shoppingListItem.findUnique({
          where: {
            userId_ingredientId: {
              userId: user.id,
              ingredientId: ingredient.id,
            },
          },
        });

        if (!existing) {
          await prismaAny.shoppingListItem.create({
            data: {
              userId: user.id,
              ingredientId: ingredient.id,
              checked: false,
              amount: item.amount || null,
            },
          });
        } else if (item.amount) {
          await prismaAny.shoppingListItem.update({
            where: { id: existing.id },
            data: { amount: item.amount },
          });
        }
        addedItems.push(item.amount ? `${item.amount} ${item.name}` : item.name);
      }
    }

    res.json(addedItems);
  } catch (error) {
    console.error('Internal add recipe to shopping list failed', error);
    res.status(500).json({ error: 'Internal add recipe to shopping list failed' });
  }
};
