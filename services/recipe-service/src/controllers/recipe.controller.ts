import { readFile, unlink } from 'fs/promises';
import { Response } from 'express';
import axios from 'axios';
import { resolve } from 'path';
import { z } from 'zod';
import prisma from '../services/prismaClient';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import { DEFAULT_RECIPE_IMAGE_URL, deleteImageByPublicUrl, uploadImage } from '../services/storageService';
import logger from '../services/logger';

const AI_SERVICE_BASE_URL = (process.env.AI_SERVICE_URL ?? 'http://127.0.0.1:8000/api').replace(/\/$/, '');
const SEARCH_MAX_DISTANCE = Number(process.env.SEARCH_MAX_DISTANCE ?? '0.5');

interface EmbeddingApiResponse {
  embedding: number[];
}

interface HealthScoreApiResponse {
  health_score: number;
}

const toVectorLiteral = (embedding: number[]): string =>
  `[${embedding.map((value) => Number(value).toString()).join(',')}]`;

const buildRecipeEmbeddingText = (title: string, ingredientNames: string[], instructions: string[]): string =>
  `Title: ${title}\nIngredients: ${ingredientNames.join(', ')}\nInstructions: ${instructions.join(' ')}`;

const generateEmbedding = async (text: string): Promise<number[]> => {
  logger.info('Calling AI Service for: generate embedding');
  const response = await axios.post<EmbeddingApiResponse>(`${AI_SERVICE_BASE_URL}/embeddings`, { text });
  const embedding = response.data?.embedding;

  if (!Array.isArray(embedding) || embedding.length === 0) {
    throw new Error('AI service returned an invalid embedding payload');
  }

  return embedding;
};

const requestAiHealthScore = async (
  title: string,
  ingredients: string[],
  instructions: string[],
): Promise<number> => {
  logger.info(`Requesting AI health score for: ${title}`);

  try {
    const response = await axios.post<HealthScoreApiResponse>(
      `${AI_SERVICE_BASE_URL}/analyze-health-score`,
      {
        title,
        ingredients,
        instructions,
      },
    );

    const score = response.data?.health_score;
    if (typeof score !== 'number' || Number.isNaN(score)) {
      throw new Error('AI service returned an invalid health score payload');
    }

    return Math.max(0, Math.min(100, Math.round(score)));
  } catch (error: any) {
    logger.warn(
      `AI health score unavailable for \"${title}\". Falling back to default score 50. Reason: ${error?.message ?? 'Unknown error'}`,
    );
    return 50;
  }
};

const saveRecipeEmbedding = async (recipeId: string, embedding: number[]): Promise<void> => {
  const vector = toVectorLiteral(embedding);

  await prisma.$executeRaw`
    UPDATE "Recipe"
    SET "embedding" = CAST(${vector} AS vector)
    WHERE "id" = ${recipeId}
  `;
};

const ingredientSchema = z.object({
  name: z.string().min(1),
  amount: z.string().trim().min(1).optional(),
  icon: z.string().trim().optional(),
});

const parseIngredients = (value: unknown): unknown => {
  if (value === undefined || value === null || value === '') {
    return [];
  }

  if (Array.isArray(value)) {
    return value;
  }

  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch {
      return value
        .split(',')
        .map((name) => name.trim())
        .filter(Boolean)
        .map((name) => ({ name }));
    }
  }

  return value;
};

const parseInstructionSteps = (value: unknown): unknown => {
  if (value === undefined || value === null || value === '') {
    return [];
  }

  if (Array.isArray(value)) {
    return value;
  }

  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      if (Array.isArray(parsed)) {
        return parsed;
      }
    } catch {
      // Fall through to newline splitting.
    }

    return value
      .split(/\r?\n/)
      .map((step) => step.trim())
      .filter(Boolean);
  }

  return value;
};

const parseBooleanish = (value: unknown): boolean | undefined => {
  if (value === undefined || value === null || value === '') {
    return undefined;
  }

  if (typeof value === 'boolean') {
    return value;
  }

  if (typeof value === 'number') {
    if (value === 1) {
      return true;
    }
    if (value === 0) {
      return false;
    }
    return undefined;
  }

  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (['true', '1', 'yes', 'y'].includes(normalized)) {
      return true;
    }
    if (['false', '0', 'no', 'n'].includes(normalized)) {
      return false;
    }
  }

  return undefined;
};

const createRecipeSchema = z.object({
  title: z.string().min(1),
  instructions: z.preprocess(
    parseInstructionSteps,
    z.array(z.string().min(1)).default([]),
  ),
  ingredients: z.preprocess(parseIngredients, z.array(ingredientSchema).default([])),
  remove_image: z.preprocess(parseBooleanish, z.boolean().optional()).optional(),
}).strict();

const semanticSearchSchema = z.object({
  query: z.string().min(1),
});

const ingredientLookupSchema = z.object({
  q: z.string().trim().min(1),
});

export interface IngredientDTO {
  name: string;
  icon: string;
  amount?: string;
}

export interface IngredientSuggestionDTO {
  name: string;
  icon: string;
}

export interface RecipeDTO {
  id: string;
  title: string;
  instructions: string[];
  healthScore: number;
  imageUrl: string;
  authorId: string;
  ingredients: IngredientDTO[];
}

const mapRecipeToDTO = (recipe: any): RecipeDTO => ({
  id: recipe.id,
  title: recipe.title,
  instructions: Array.isArray(recipe.instructions) ? recipe.instructions : [],
  healthScore: recipe.healthScore,
  imageUrl: recipe.imageUrl ?? DEFAULT_RECIPE_IMAGE_URL,
  authorId: recipe.authorId,
  ingredients:
    recipe.ingredients?.map((ri: any) => ({
      name: ri.ingredient.name,
      icon: ri.ingredient.icon ?? '',
      amount:
        typeof ri.amount === 'string' && ri.amount.trim().length > 0
          ? ri.amount.trim()
          : undefined,
    })) ?? [],
});

interface NormalizedIngredient {
  name: string;
  amount?: string;
  icon?: string;
}

const normalizeIngredients = (ingredients: { name: string; amount?: string; icon?: string }[]): NormalizedIngredient[] => {
  const byName = new Map<string, NormalizedIngredient>();

  for (const ingredient of ingredients) {
    const normalizedName = ingredient.name.toLowerCase().trim();
    if (!normalizedName) {
      continue;
    }

    const normalizedAmount = ingredient.amount?.trim();
    const normalizedIcon = ingredient.icon?.trim();
    const existing = byName.get(normalizedName);

    if (!existing) {
      byName.set(normalizedName, {
        name: normalizedName,
        amount: normalizedAmount && normalizedAmount.length > 0 ? normalizedAmount : undefined,
        icon: normalizedIcon && normalizedIcon.length > 0 ? normalizedIcon : undefined,
      });
      continue;
    }

    if (!existing.amount && normalizedAmount && normalizedAmount.length > 0) {
      existing.amount = normalizedAmount;
    }

    if (!existing.icon && normalizedIcon && normalizedIcon.length > 0) {
      existing.icon = normalizedIcon;
    }
  }

  return Array.from(byName.values());
};

const cleanupTempUpload = async (file?: Express.Multer.File): Promise<void> => {
  if (!file?.path) {
    return;
  }

  const absolutePath = resolve(file.path);

  try {
    await unlink(absolutePath);
    logger.info(`Cleaned up temporary file: ${absolutePath}`);
  } catch (error: any) {
    if (error?.code !== 'ENOENT') {
      // eslint-disable-next-line no-console
      console.warn(`Failed to clean temporary file at ${absolutePath}:`, error.message);
    } else {
      // eslint-disable-next-line no-console
      console.warn(`Temporary file not found at ${absolutePath} (may have been deleted already)`);
    }
  }
};

const getAiServiceErrorMessage = (error: unknown): string => {
  if (axios.isAxiosError(error)) {
    const detail = error.response?.data?.detail;
    if (typeof detail === 'string' && detail.trim().length > 0) {
      return detail;
    }

    const errorMessage = error.response?.data?.error;
    if (typeof errorMessage === 'string' && errorMessage.trim().length > 0) {
      return errorMessage;
    }

    if (typeof error.message === 'string' && error.message.trim().length > 0) {
      return error.message;
    }
  }

  if (error instanceof Error && error.message.trim().length > 0) {
    return error.message;
  }

  return 'Failed to create recipe from image';
};

export const createRecipeFromImage = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    if (!req.file?.path) {
      res.status(400).json({ error: 'Image file is required' });
      return;
    }

    if (!req.file.mimetype || !req.file.mimetype.toLowerCase().startsWith('image/')) {
      res.status(400).json({ error: 'Uploaded file must be an image' });
      return;
    }

    const imageBytes = await readFile(resolve(req.file.path));
    const imageBase64 = imageBytes.toString('base64');

    logger.info('Calling AI Service for: generate recipe from image');
    const response = await axios.post(
      `${AI_SERVICE_BASE_URL}/generate-recipe-from-image`,
      {
        image_base64: imageBase64,
        mime_type: req.file.mimetype,
      },
      {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 90000,
      },
    );

    res.status(200).json(response.data);
  } catch (error) {
    const statusCode = axios.isAxiosError(error)
      ? (error.response?.status ?? 500)
      : 500;

    const userFacingStatus = statusCode >= 400 && statusCode < 500 ? statusCode : 500;
    res.status(userFacingStatus).json({
      error: getAiServiceErrorMessage(error),
    });
  } finally {
    await cleanupTempUpload(req.file);
  }
};

export const createRecipe = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const parsed = createRecipeSchema.safeParse(req.body);

    if (!parsed.success) {
      res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
      return;
    }

    const { title, instructions, ingredients } = parsed.data;
    const imageUrl = req.file ? await uploadImage(req.file) : DEFAULT_RECIPE_IMAGE_URL;

    const normalizedIngredients = normalizeIngredients(ingredients);
    const ingredientNames = normalizedIngredients.map((ingredient) => ingredient.name);
    const healthScore = await requestAiHealthScore(title, ingredientNames, instructions);

    const createData: any = {
      title,
      instructions,
      healthScore,
      author: {
        connectOrCreate: {
          where: { authId: req.user.id },
          create: {
            authId: req.user.id,
          },
        },
      },
      ingredients: {
        create: normalizedIngredients.map((ingredient) => ({
          amount: ingredient.amount,
          ingredient: {
            connectOrCreate: {
              where: { name: ingredient.name },
              create: { 
                name: ingredient.name,
                ...(ingredient.icon && { icon: ingredient.icon }),
              },
            },
          },
        })),
      },
      imageUrl,
    };

    const createdRecipe = await prisma.recipe.create({
      data: createData,
      include: {
        ingredients: {
          include: {
            ingredient: true,
          },
        },
      },
    });

    await Promise.all(
      normalizedIngredients
        .filter((ingredient) => Boolean(ingredient.icon))
        .map((ingredient) =>
          prisma.ingredient.updateMany({
            where: {
              name: ingredient.name,
              icon: '',
            },
            data: {
              icon: ingredient.icon,
            },
          }),
        ),
    );

    try {
      const embeddingText = buildRecipeEmbeddingText(title, ingredientNames, instructions);
      const embedding = await generateEmbedding(embeddingText);
      await saveRecipeEmbedding(createdRecipe.id, embedding);
    } catch (embeddingError) {
      // eslint-disable-next-line no-console
      console.warn('Recipe created but embedding generation failed', embeddingError);
    }

    res.status(201).json(mapRecipeToDTO(createdRecipe));
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error creating recipe', error);
    res.status(500).json({ error: 'Failed to create recipe' });
  } finally {
    await cleanupTempUpload(req.file);
  }
};

export const searchRecipes = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const parsed = semanticSearchSchema.safeParse(req.body);

    if (!parsed.success) {
      res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
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

    const embedding = await generateEmbedding(parsed.data.query);
    const vector = toVectorLiteral(embedding);

    const searchResults = await prisma.$queryRaw<Array<{ id: string; distance: number }>>`
      SELECT "id", ("embedding" <=> CAST(${vector} AS vector)) AS "distance"
      FROM "Recipe"
      WHERE "embedding" IS NOT NULL
        AND "authorId" = ${user.id}
        AND ("embedding" <=> CAST(${vector} AS vector)) <= ${SEARCH_MAX_DISTANCE}
      ORDER BY "embedding" <=> CAST(${vector} AS vector)
      LIMIT 5
    `;

    logger.info(`Calling AI Service for: semantic search embedding for query \"${parsed.data.query}\"`);

    const recipeIds = searchResults.map((result) => result.id);

    if (recipeIds.length === 0) {
      res.json([]);
      return;
    }

    const recipes = await prisma.recipe.findMany({
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
    const orderedRecipes = recipeIds
      .map((id) => recipeById.get(id))
      .filter((recipe): recipe is NonNullable<typeof recipe> => Boolean(recipe));

    res.json(orderedRecipes.map(mapRecipeToDTO));
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error searching recipes semantically', error);
    res.status(500).json({ error: 'Failed to search recipes' });
  }
};

export const searchIngredients = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const parsed = ingredientLookupSchema.safeParse(req.query);
    if (!parsed.success) {
      res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
      return;
    }

    const query = parsed.data.q;
    const ingredients = await prisma.ingredient.findMany({
      where: {
        name: {
          contains: query,
          mode: 'insensitive',
        },
      },
      orderBy: {
        name: 'asc',
      },
      select: {
        name: true,
        icon: true,
      },
      take: 10,
    });

    const payload: IngredientSuggestionDTO[] = ingredients.map((ingredient) => ({
      name: ingredient.name,
      icon: ingredient.icon,
    }));

    res.json(payload);
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error searching ingredients', error);
    res.status(500).json({ error: 'Failed to search ingredients' });
  }
};

export const getRecipes = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { authId: req.user.id },
      include: {
        recipes: {
          include: {
            ingredients: {
              include: {
                ingredient: true,
              },
            },
          },
        },
      },
    });

    if (!user) {
      res.json([]);
      return;
    }

    const recipes = user.recipes.map(mapRecipeToDTO);

    res.json(recipes);
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error fetching recipes', error);
    res.status(500).json({ error: 'Failed to fetch recipes' });
  }
};

export const getRecipeById = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { id } = req.params;

    const recipe = await prisma.recipe.findFirst({
      where: {
        id,
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
      res.status(404).json({ error: 'Recipe not found' });
      return;
    }

    res.json(mapRecipeToDTO(recipe));
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error fetching recipe', error);
    res.status(500).json({ error: 'Failed to fetch recipe' });
  }
};

export const updateRecipe = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { id } = req.params;

    const parsed = createRecipeSchema.safeParse(req.body);

    if (!parsed.success) {
      res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
      return;
    }

    const existingRecipe = await prisma.recipe.findFirst({
      where: {
        id,
        author: {
          authId: req.user.id,
        },
      },
      select: {
        id: true,
        imageUrl: true,
      },
    });

    if (!existingRecipe) {
      res.status(404).json({ error: 'Recipe not found' });
      return;
    }

    const { title, instructions, ingredients, remove_image: removeImage } = parsed.data;
    const normalizedIngredients = normalizeIngredients(ingredients);
    const ingredientNames = normalizedIngredients.map((ingredient) => ingredient.name);
    const healthScore = await requestAiHealthScore(title, ingredientNames, instructions);
    const previousImageUrl = existingRecipe.imageUrl ?? null;
    const imageUrl = req.file
      ? await uploadImage(req.file)
      : removeImage
        ? DEFAULT_RECIPE_IMAGE_URL
      : existingRecipe.imageUrl ?? DEFAULT_RECIPE_IMAGE_URL;

    const updatedRecipe = await prisma.recipe.update({
      where: {
        id: existingRecipe.id,
      },
      data: {
        title,
        instructions,
        healthScore,
        imageUrl,
        ingredients: {
          deleteMany: {},
          create: normalizedIngredients.map((ingredient) => ({
            amount: ingredient.amount,
            ingredient: {
              connectOrCreate: {
                where: { name: ingredient.name },
                create: { name: ingredient.name },
              },
            },
          })),
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

    try {
      const embeddingText = buildRecipeEmbeddingText(title, ingredientNames, instructions);
      const embedding = await generateEmbedding(embeddingText);
      await saveRecipeEmbedding(updatedRecipe.id, embedding);
    } catch (embeddingError) {
      // eslint-disable-next-line no-console
      console.warn('Recipe updated but embedding generation failed', embeddingError);
    }

    const shouldDeletePreviousImage =
      !!previousImageUrl
      && previousImageUrl !== DEFAULT_RECIPE_IMAGE_URL
      && (Boolean(req.file) || removeImage === true);

    if (shouldDeletePreviousImage) {
      try {
        await deleteImageByPublicUrl(previousImageUrl);
      } catch (deleteImageError: any) {
        logger.warn(`Recipe updated but old image cleanup failed: ${deleteImageError?.message ?? 'Unknown error'}`);
      }
    }

    res.json(mapRecipeToDTO(updatedRecipe));
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error updating recipe', error);
    res.status(500).json({ error: 'Failed to update recipe' });
  } finally {
    await cleanupTempUpload(req.file);
  }
};

export const deleteRecipe = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { id } = req.params;

    const existingRecipe = await prisma.recipe.findFirst({
      where: {
        id,
        author: {
          authId: req.user.id,
        },
      },
      select: {
        id: true,
        imageUrl: true,
      },
    });

    if (!existingRecipe) {
      res.status(404).json({ error: 'Recipe not found' });
      return;
    }

    await prisma.$transaction([
      prisma.recipeIngredient.deleteMany({
        where: {
          recipeId: existingRecipe.id,
        },
      }),
      prisma.recipe.delete({
        where: {
          id: existingRecipe.id,
        },
      }),
    ]);

    if (existingRecipe.imageUrl && existingRecipe.imageUrl !== DEFAULT_RECIPE_IMAGE_URL) {
      try {
        await deleteImageByPublicUrl(existingRecipe.imageUrl);
      } catch (deleteImageError: any) {
        logger.warn(`Recipe deleted but image cleanup failed: ${deleteImageError?.message ?? 'Unknown error'}`);
      }
    }

    res.status(204).send();
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error deleting recipe', error);
    res.status(500).json({ error: 'Failed to delete recipe' });
  }
};

