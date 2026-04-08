import axios from 'axios';
import { Response } from 'express';
import { Readable } from 'stream';
import { z } from 'zod';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import prisma from '../services/prismaClient';
import logger from '../services/logger';

const chatRequestSchema = z
  .object({
    prompt: z.string().min(1),
    page_context: z.enum(['home', 'recipe_detail']),
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

type RouterIntent =
  | 'CREATE_RECIPE'
  | 'SEARCH_RECIPES'
  | 'HEALTH_AUDIT'
  | 'ASSISTANT_HELP'
  | 'GENERAL_CHAT';

interface RouterResponsePayload {
  intent: RouterIntent;
  confidence: number;
}

interface FlushableResponse extends Response {
  flush?: () => void;
}

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

const getInitFailureStatusCode = (error: unknown): number => {
  const upstreamStatus = getAxiosStatusCode(error);
  return upstreamStatus === 429 ? 429 : 500;
};

const getAxiosRetryAfter = (error: unknown): string | null => {
  if (!axios.isAxiosError(error)) {
    return null;
  }

  const retryAfter = error.response?.headers?.['retry-after'];
  if (typeof retryAfter === 'string' && retryAfter.trim().length > 0) {
    return retryAfter;
  }

  return null;
};

const parseRetryAfterSeconds = (
  rawMessage: string,
  retryAfterHeader: string | null,
): number | null => {
  if (retryAfterHeader) {
    const fromHeader = Number.parseInt(retryAfterHeader, 10);
    if (Number.isFinite(fromHeader) && fromHeader > 0) {
      return fromHeader;
    }
  }

  const retryInMatch = rawMessage.match(/retry in\s+([0-9]+(?:\.[0-9]+)?)s/i);
  if (retryInMatch) {
    return Math.max(1, Math.round(Number.parseFloat(retryInMatch[1])));
  }

  const retryDelayMatch = rawMessage.match(/retryDelay[^0-9]*([0-9]+)s/i);
  if (retryDelayMatch) {
    return Math.max(1, Number.parseInt(retryDelayMatch[1], 10));
  }

  return null;
};

const getFriendlyAiErrorMessage = (
  rawMessage: string,
  retryAfterHeader: string | null = null,
): string => {
  const normalized = rawMessage.toLowerCase();
  const isRateLimited =
    normalized.includes('resource_exhausted')
    || normalized.includes('quota')
    || normalized.includes('rate limit')
    || normalized.includes('429');

  if (isRateLimited) {
    const retryAfterSeconds = parseRetryAfterSeconds(rawMessage, retryAfterHeader);
    if (retryAfterSeconds) {
      return `Rate limit reached, please try again in ${retryAfterSeconds} seconds.`;
    }
    return 'Rate limit reached, please try again shortly.';
  }

  return 'AI service is temporarily unavailable. Please try again.';
};

const getUserFacingAxiosErrorMessage = (error: unknown): string => {
  const rawMessage = getAxiosErrorMessage(error);
  const retryAfter = getAxiosRetryAfter(error);
  return getFriendlyAiErrorMessage(rawMessage, retryAfter);
};

const logAxiosFailure = (label: string, error: unknown): void => {
  logger.error(
    `${label} | status=${getAxiosStatusCode(error)} | retryAfter=${getAxiosRetryAfter(error) ?? 'none'} | detail=${getAxiosErrorMessage(error)}`,
  );
};

const sendInitFailureJson = (
  res: Response,
  error: unknown,
  intent: RouterIntent,
): void => {
  const statusCode = getInitFailureStatusCode(error);
  const retryAfter = getAxiosRetryAfter(error);
  if (retryAfter) {
    res.setHeader('Retry-After', retryAfter);
  }

  res.status(statusCode).json({
    error: getUserFacingAxiosErrorMessage(error),
    intent,
  });
};

const writeSseDelta = (res: FlushableResponse, content: string): void => {
  if (!content) {
    return;
  }

  res.write(`data: ${JSON.stringify({ delta: content })}\n\n`);
  res.flush?.();
};

/**
 * Forward already SSE-formatted stream from upstream.
 * This handles the new structured format where Python sends: data: {"delta": "...", "type": "text"}\n\n
 */
const forwardStructuredSseStream = (
  req: AuthenticatedRequest,
  res: FlushableResponse,
  upstreamStream: Readable,
  onAbort: () => void,
): void => {
  let streamClosed = false;
  let buffer = '';

  const closeStream = (): void => {
    if (streamClosed) {
      return;
    }

    streamClosed = true;
    if (!res.writableEnded) {
      res.end();
    }
  };

  req.on('close', () => {
    onAbort();
    if (!upstreamStream.destroyed) {
      upstreamStream.destroy();
    }
    closeStream();
  });

  upstreamStream.on('data', (chunk: Buffer | string) => {
    try {
      const chunkText = chunk.toString();
      if (!chunkText) {
        return;
      }

      // Accumulate chunks until we have complete SSE lines
      buffer += chunkText;

      // Process complete lines (ending with \n\n for SSE)
      let lineEndIndex = buffer.indexOf('\n\n');
      while (lineEndIndex !== -1) {
        const sseLine = buffer.substring(0, lineEndIndex + 2);
        // Forward the SSE line as-is (already properly formatted from upstream)
        res.write(sseLine);
        res.flush?.();

        buffer = buffer.substring(lineEndIndex + 2);
        lineEndIndex = buffer.indexOf('\n\n');
      }
    } catch (streamParseError) {
      // eslint-disable-next-line no-console
      console.error('AI structured stream parse failed', streamParseError);
      onAbort();
      closeStream();
    }
  });

  upstreamStream.on('end', () => {
    // Flush any remaining buffer content
    if (buffer.trim()) {
      res.write(buffer);
    }
    logger.info('AI stream completed');
    closeStream();
  });

  upstreamStream.on('error', (streamError: Error) => {
    // eslint-disable-next-line no-console
    console.error('AI upstream stream failed', streamError);
    onAbort();

    if (!res.writableEnded) {
      // Send error as SSE formatted JSON
      const errorObj = JSON.stringify({ type: 'error', message: 'AI stream interrupted. Please try again.' });
      res.write(`data: ${errorObj}\n\n`);
    }

    closeStream();
  });
};

export const streamChat = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

  const parsed = chatRequestSchema.safeParse(req.body);

  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  const { prompt, page_context, recipe_id } = parsed.data;

  let recipeContext: string | null = null;
  if (page_context === 'recipe_detail' && recipe_id) {
    try {
      recipeContext = await loadRecipeContext(req, recipe_id);
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Failed to load recipe context', { recipeId: recipe_id, error });
      res.status(500).json({ error: 'Failed to load recipe context' });
      return;
    }

    if (!recipeContext) {
      res.status(404).json({ error: 'Recipe not found' });
      return;
    }
  }

  let routedIntent: RouterResponsePayload;
  try {
    logger.info('Calling AI Service for: intent routing');
    const routeResponse = await axios.post<RouterResponsePayload>(
      `${AI_SERVICE_API_BASE_URL}/route`,
      { prompt, page_context, recipe_context: recipeContext },
      {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      },
    );

    routedIntent = routeResponse.data;
    logger.info(`Intent detected: ${routedIntent.intent}`);
  } catch (error) {
    logAxiosFailure('AI router request failed', error);

    const statusCode = getAxiosStatusCode(error);
    const retryAfter = getAxiosRetryAfter(error);
    if (retryAfter) {
      res.setHeader('Retry-After', retryAfter);
    }

    res.status(statusCode).json({
      error: getUserFacingAxiosErrorMessage(error),
    });
    return;
  }

  const streamFromAi = async (endpoint: string): Promise<void> => {
    const streamingResponse = res as FlushableResponse;
    const upstreamAbortController = new AbortController();
    const initializeGeminiStream = async (): Promise<Readable | null> => {
      try {
        logger.info(`Calling AI Service for: ${endpoint}`);
        const upstreamResponse = await axios.post(
          `${AI_SERVICE_API_BASE_URL}${endpoint}`,
          { prompt, recipe_context: recipeContext },
          {
            headers: {
              Accept: 'text/event-stream',
              'Content-Type': 'application/json',
            },
            responseType: 'stream',
            signal: upstreamAbortController.signal,
            timeout: 0,
          },
        );

        return upstreamResponse.data as Readable;
      } catch (error) {
        logAxiosFailure('AI stream initialization failed', error);
        sendInitFailureJson(res, error, routedIntent.intent);
        return null;
      }
    };

    const upstreamStream = await initializeGeminiStream();
    if (!upstreamStream) {
      return;
    }

    try {
      streamingResponse.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
        'X-Accel-Buffering': 'no',
      });
      streamingResponse.flushHeaders();

      // Use the new structured SSE handler since Python now sends properly formatted SSE
      forwardStructuredSseStream(req, streamingResponse, upstreamStream, () => {
        upstreamAbortController.abort();
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('AI stream setup failed after initialization', error);
      if (!streamingResponse.headersSent) {
        sendInitFailureJson(streamingResponse, error, routedIntent.intent);
      } else if (!streamingResponse.writableEnded) {
        writeSseDelta(streamingResponse, 'AI stream interrupted. Please try again.');
        streamingResponse.end();
      }
    }
  };

  switch (routedIntent.intent) {
    case 'ASSISTANT_HELP':
    case 'GENERAL_CHAT':
      await streamFromAi('/stream-assistant');
      return;
    case 'HEALTH_AUDIT':
      await streamFromAi('/stream-health');
      return;
    case 'CREATE_RECIPE': {
      try {
        logger.info('Calling AI Service for: generate recipe');
        const recipeResponse = await axios.post(
          `${AI_SERVICE_API_BASE_URL}/generate-recipe`,
          { prompt, recipe_context: recipeContext },
          {
            headers: {
              'Content-Type': 'application/json',
            },
            timeout: 60000,
          },
        );
        res.status(200).json(recipeResponse.data);
      } catch (error) {
        logAxiosFailure('AI recipe generation failed', error);

        const statusCode = getAxiosStatusCode(error);
        const retryAfter = getAxiosRetryAfter(error);
        if (retryAfter) {
          res.setHeader('Retry-After', retryAfter);
        }

        res.status(statusCode).json({
          error: getUserFacingAxiosErrorMessage(error),
        });
      }
      return;
    }
    case 'SEARCH_RECIPES': {
      const streamSemanticSearch = async (): Promise<void> => {
        try {
          logger.info('Calling AI Service for: search specialist');
          const searchFiltersResponse = await axios.post(
            `${AI_SERVICE_API_BASE_URL}/search-specialist`,
            { prompt, recipe_context: recipeContext },
            {
              headers: {
                'Content-Type': 'application/json',
              },
              timeout: 30000,
            },
          );

          const searchFilters = searchFiltersResponse.data;
          const normalizedQuery = searchFilters.query || prompt;

          // Get user context
          if (!req.user?.id) {
            res.status(401).json({ error: 'Unauthorized' });
            return;
          }

          const user = await prisma.user.findUnique({
            where: { authId: req.user.id },
            select: { id: true },
          });

          if (!user) {
            res.writeHead(200, {
              'Content-Type': 'text/event-stream',
              'Cache-Control': 'no-cache',
              Connection: 'keep-alive',
              'X-Accel-Buffering': 'no',
            });
            res.write(`data: ${JSON.stringify({ type: 'searchResults', recipes: [] })}\n\n`);
            res.write('data: [DONE]\n\n');
            res.end();
            return;
          }

          // Generate embedding for the normalized query
          logger.info(`Generating embedding for semantic search: "${normalizedQuery}"`);
          const embeddingResponse = await axios.post(
            `${AI_SERVICE_API_BASE_URL}/embeddings`,
            { text: normalizedQuery },
            {
              headers: {
                'Content-Type': 'application/json',
              },
              timeout: 30000,
            },
          );

          const embedding = embeddingResponse.data?.embedding;
          if (!Array.isArray(embedding) || embedding.length === 0) {
            throw new Error('Invalid embedding response from AI service');
          }

          // Convert embedding to vector literal
          const vectorLiteral = `[${embedding.map((v: number) => Number(v).toString()).join(',')}]`;
          const SEARCH_MAX_DISTANCE = Number(process.env.SEARCH_MAX_DISTANCE ?? '0.5');

          // Search recipes using vector similarity (pgvector)
          const searchResults = await prisma.$queryRaw<Array<{ id: string; distance: number }>>`
            SELECT "id", ("embedding" <=> CAST(${vectorLiteral} AS vector)) AS "distance"
            FROM "Recipe"
            WHERE "embedding" IS NOT NULL
              AND "authorId" = ${user.id}
              AND ("embedding" <=> CAST(${vectorLiteral} AS vector)) <= ${SEARCH_MAX_DISTANCE}
            ORDER BY "embedding" <=> CAST(${vectorLiteral} AS vector)
            LIMIT 3
          `;

          logger.info(`Found ${searchResults.length} recipes matching the search`);

          // Fetch full recipe details
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

            // Sort recipes based on search order
            const recipeById = new Map(recipes.map((recipe) => [recipe.id, recipe]));
            recipes = recipeIds
              .map((id) => recipeById.get(id))
              .filter(Boolean);
          }

          // Map recipes to DTO format
          const recipeDTOs = recipes.map((recipe) => ({
            id: recipe.id,
            title: recipe.title,
            healthScore: recipe.healthScore,
            imageUrl: recipe.imageUrl || 'https://images.unsplash.com/photo-1495521821757-a1efb6729352?w=300&h=200',
            ingredients: recipe.ingredients?.map((ri: any) => ri.ingredient.name) || [],
          }));

          // Send SSE response with search results
          res.writeHead(200, {
            'Content-Type': 'text/event-stream',
            'Cache-Control': 'no-cache',
            Connection: 'keep-alive',
            'X-Accel-Buffering': 'no',
          });

          // Send introduction message
          const introMessage = recipeIds.length > 0
            ? `Here are the recipes I found for you:`
            : `I couldn't find any recipes matching "${normalizedQuery}". Try different keywords or ingredients!`;

          res.write(`data: ${JSON.stringify({ delta: introMessage, type: 'text' })}\n\n`);

          // Send search results as metadata event
          if (recipeIds.length > 0) {
            res.write(`data: ${JSON.stringify({ type: 'searchResults', recipes: recipeDTOs })}\n\n`);
          }

          // Signal completion
          res.write('data: [DONE]\n\n');
          res.end();
        } catch (error) {
          logAxiosFailure('AI semantic search failed', error);

          const streamingResponse = res as FlushableResponse;
          if (!streamingResponse.headersSent) {
            streamingResponse.writeHead(200, {
              'Content-Type': 'text/event-stream',
              'Cache-Control': 'no-cache',
              Connection: 'keep-alive',
              'X-Accel-Buffering': 'no',
            });
          }

          const errorMessage = getUserFacingAxiosErrorMessage(error);
          streamingResponse.write(`data: ${JSON.stringify({ delta: errorMessage, type: 'text' })}\n\n`);
          streamingResponse.write('data: [DONE]\n\n');
          streamingResponse.end();
        }
      };

      await streamSemanticSearch();
      return;
    }
    default:
      res.status(400).json({ error: `Unsupported intent: ${routedIntent.intent}` });
  }
};