import { unlink } from 'fs/promises';
import { Response } from 'express';
import axios from 'axios';
import { resolve } from 'path';
import { z } from 'zod';
import prisma from '../services/prismaClient';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import { DEFAULT_RECIPE_IMAGE_URL, uploadImage } from '../services/storageService';

const AI_SERVICE_BASE_URL = (process.env.AI_SERVICE_URL ?? 'http://127.0.0.1:8000/api').replace(/\/$/, '');
const SEARCH_MAX_DISTANCE = Number(process.env.SEARCH_MAX_DISTANCE ?? '0.5');

interface EmbeddingApiResponse {
  embedding: number[];
}

const toVectorLiteral = (embedding: number[]): string =>
  `[${embedding.map((value) => Number(value).toString()).join(',')}]`;

const buildRecipeEmbeddingText = (title: string, ingredientNames: string[], instructions: string[]): string =>
  `Title: ${title}\nIngredients: ${ingredientNames.join(', ')}\nInstructions: ${instructions.join(' ')}`;

const generateEmbedding = async (text: string): Promise<number[]> => {
  const response = await axios.post<EmbeddingApiResponse>(`${AI_SERVICE_BASE_URL}/embeddings`, { text });
  const embedding = response.data?.embedding;

  if (!Array.isArray(embedding) || embedding.length === 0) {
    throw new Error('AI service returned an invalid embedding payload');
  }

  return embedding;
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

const createRecipeSchema = z.object({
  title: z.string().min(1),
  instructions: z.preprocess(
    parseInstructionSteps,
    z.array(z.string().min(1)).min(1),
  ),
  healthScore: z.coerce.number().int().min(0).max(100),
  ingredients: z.preprocess(parseIngredients, z.array(ingredientSchema).default([])),
});

const semanticSearchSchema = z.object({
  query: z.string().min(1),
});

export interface IngredientDTO {
  name: string;
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
    })) ?? [],
});

const cleanupTempUpload = async (file?: Express.Multer.File): Promise<void> => {
  if (!file?.path) {
    return;
  }

  const absolutePath = resolve(file.path);

  try {
    await unlink(absolutePath);
    // eslint-disable-next-line no-console
    console.log(`Cleaned up temporary file: ${absolutePath}`);
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

export const createRecipe = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const parsed = createRecipeSchema.safeParse(req.body);

    if (!parsed.success) {
      res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
      return;
    }

    const { title, instructions, healthScore, ingredients } = parsed.data;
    const imageUrl = req.file ? await uploadImage(req.file) : DEFAULT_RECIPE_IMAGE_URL;

    const ingredientNames = ingredients.map((i) => i.name.toLowerCase().trim());

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
        create: ingredientNames.map((name) => ({
          ingredient: {
            connectOrCreate: {
              where: { name },
              create: { name },
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

    // Temporary debug line:
    console.log('QUERY:', parsed.data.query);
    console.log('RESULTS FOUND:', searchResults.map(r => ({ id: r.id, dist: r.distance })));

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

export const getRecipes = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
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

