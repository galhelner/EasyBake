import { Response } from 'express';
import { z } from 'zod';
import prisma from '../services/prismaClient';
import { AuthenticatedRequest } from '../middleware/authMiddleware';

const prismaAny = prisma as any;

const shoppingListItemSchema = z.object({
  ingredientName: z.string().trim().min(1),
  checked: z.boolean().optional(),
  amount: z.string().trim().optional().nullable(),
});

const updateShoppingListItemSchema = z
  .object({
    ingredientName: z.string().trim().min(1).optional(),
    checked: z.boolean().optional(),
    amount: z.string().trim().optional().nullable(),
  })
  .refine((value) => value.ingredientName !== undefined || value.checked !== undefined || value.amount !== undefined, {
    message: 'At least one field must be provided',
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

const mapShoppingListItem = (item: {
  id: string;
  checked: boolean;
  amount?: string | null;
  createdAt: Date;
  updatedAt: Date;
  ingredient: { id: string; name: string; icon: string };
}) => ({
  id: item.id,
  checked: item.checked,
  amount: item.amount || null,
  createdAt: item.createdAt,
  updatedAt: item.updatedAt,
  ingredient: {
    id: item.ingredient.id,
    name: item.ingredient.name,
    icon: item.ingredient.icon,
  },
});

export const getShoppingList = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const user = await ensureUser(req.user.id);

    const shoppingListItems = await prismaAny.shoppingListItem.findMany({
      where: { userId: user.id },
      include: {
        ingredient: true,
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    res.json(shoppingListItems.map(mapShoppingListItem));
  } catch (error) {
    console.error('Error fetching shopping list', error);
    res.status(500).json({ error: 'Failed to fetch shopping list' });
  }
};

export const createShoppingListItem = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const parsed = shoppingListItemSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
      return;
    }

    const user = await ensureUser(req.user.id);
    const ingredient = await ensureIngredient(parsed.data.ingredientName);
    const checked = parsed.data.checked ?? false;
    const amount = parsed.data.amount ?? null;

    const shoppingListItem = await prismaAny.shoppingListItem.upsert({
      where: {
        userId_ingredientId: {
          userId: user.id,
          ingredientId: ingredient.id,
        },
      },
      update: {
        checked,
        amount,
      },
      create: {
        userId: user.id,
        ingredientId: ingredient.id,
        checked,
        amount,
      },
      include: {
        ingredient: true,
      },
    });

    res.status(201).json(mapShoppingListItem(shoppingListItem));
  } catch (error) {
    console.error('Error creating shopping list item', error);
    res.status(500).json({ error: 'Failed to create shopping list item' });
  }
};

export const updateShoppingListItem = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const parsed = updateShoppingListItemSchema.safeParse(req.body);
    if (!parsed.success) {
      res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
      return;
    }

    const { id } = req.params;
    const user = await ensureUser(req.user.id);

    const existingItem = await prismaAny.shoppingListItem.findFirst({
      where: {
        id,
        userId: user.id,
      },
      include: {
        ingredient: true,
      },
    });

    if (!existingItem) {
      res.status(404).json({ error: 'Shopping list item not found' });
      return;
    }

    const nextIngredientName = parsed.data.ingredientName?.trim();
    const nextChecked = parsed.data.checked;
    const nextAmount = parsed.data.amount;

    if (!nextIngredientName && typeof nextChecked !== 'boolean' && nextAmount === undefined) {
      res.status(400).json({ error: 'Validation error' });
      return;
    }

    if (nextIngredientName) {
      const ingredient = await ensureIngredient(nextIngredientName);

      if (ingredient.id !== existingItem.ingredientId) {
        const conflictingItem = await prismaAny.shoppingListItem.findUnique({
          where: {
            userId_ingredientId: {
              userId: user.id,
              ingredientId: ingredient.id,
            },
          },
        });

        if (conflictingItem && conflictingItem.id !== existingItem.id) {
          const mergedChecked = Boolean(conflictingItem.checked || existingItem.checked || nextChecked);
          const mergedAmount = nextAmount !== undefined ? nextAmount : conflictingItem.amount || existingItem.amount;

          const [updatedItem] = await prisma.$transaction([
            prismaAny.shoppingListItem.update({
              where: { id: conflictingItem.id },
              data: {
                checked: mergedChecked,
                amount: mergedAmount,
              },
              include: {
                ingredient: true,
              },
            }),
            prismaAny.shoppingListItem.delete({
              where: { id: existingItem.id },
            }),
          ]);

          res.json(mapShoppingListItem(updatedItem));
          return;
        }
      }

      const updatedItem = await prismaAny.shoppingListItem.update({
        where: { id: existingItem.id },
        data: {
          ingredientId: ingredient.id,
          ...(typeof nextChecked === 'boolean' ? { checked: nextChecked } : {}),
          ...(nextAmount !== undefined ? { amount: nextAmount } : {}),
        },
        include: {
          ingredient: true,
        },
      });

      res.json(mapShoppingListItem(updatedItem));
      return;
    }

    const updatedItem = await prismaAny.shoppingListItem.update({
      where: { id: existingItem.id },
      data: {
        ...(typeof nextChecked === 'boolean' ? { checked: nextChecked } : {}),
        ...(nextAmount !== undefined ? { amount: nextAmount } : {}),
      },
      include: {
        ingredient: true,
      },
    });

    res.json(mapShoppingListItem(updatedItem));
  } catch (error) {
    console.error('Error updating shopping list item', error);
    res.status(500).json({ error: 'Failed to update shopping list item' });
  }
};

export const deleteShoppingListItem = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  try {
    if (!req.user?.id) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }

    const { id } = req.params;
    const user = await ensureUser(req.user.id);

    const existingItem = await prismaAny.shoppingListItem.findFirst({
      where: {
        id,
        userId: user.id,
      },
      select: { id: true },
    });

    if (!existingItem) {
      res.status(404).json({ error: 'Shopping list item not found' });
      return;
    }

    await prismaAny.shoppingListItem.delete({
      where: { id: existingItem.id },
    });

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting shopping list item', error);
    res.status(500).json({ error: 'Failed to delete shopping list item' });
  }
};