import { unlink } from 'fs/promises';
import { Response } from 'express';
import { z } from 'zod';
import prisma from '../services/prismaClient';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import { DEFAULT_RECIPE_IMAGE_URL, uploadImage } from '../services/storageService';

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

  try {
    await unlink(file.path);
  } catch (error: any) {
    if (error?.code !== 'ENOENT') {
      // eslint-disable-next-line no-console
      console.warn('Failed to clean temporary uploaded file', error);
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

    res.status(201).json(mapRecipeToDTO(createdRecipe));
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error creating recipe', error);
    res.status(500).json({ error: 'Failed to create recipe' });
  } finally {
    await cleanupTempUpload(req.file);
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

