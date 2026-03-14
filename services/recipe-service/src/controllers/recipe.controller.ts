import { Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../services/prismaClient';
import { AuthenticatedRequest } from '../middleware/authMiddleware';

const ingredientSchema = z.object({
  name: z.string().min(1),
});

const createRecipeSchema = z.object({
  title: z.string().min(1),
  instructions: z.string().min(1),
  healthScore: z.number().int().min(0).max(100),
  ingredients: z.array(ingredientSchema).default([]),
});

export interface IngredientDTO {
  name: string;
}

export interface RecipeDTO {
  id: string;
  title: string;
  instructions: string;
  healthScore: number;
  authorId: string;
  ingredients: IngredientDTO[];
}

const mapRecipeToDTO = (recipe: any): RecipeDTO => ({
  id: recipe.id,
  title: recipe.title,
  instructions: recipe.instructions,
  healthScore: recipe.healthScore,
  authorId: recipe.authorId,
  ingredients:
    recipe.ingredients?.map((ri: any) => ({
      name: ri.ingredient.name,
    })) ?? [],
});

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

    const ingredientNames = ingredients.map((i) => i.name.toLowerCase().trim());

    const createdRecipe = await prisma.recipe.create({
      data: {
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
      },
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

