import axios from 'axios';
import { z } from 'zod';
import prisma from './prismaClient';
import logger from './logger';

const ingredientSchema = z.object({
  name: z.string().min(1),
  icon: z.string().min(1),
});

const ingredientArchiveSchema = z.array(ingredientSchema).min(1);

const AI_SERVICE_API_BASE_URL = (process.env.AI_SERVICE_URL ?? 'http://127.0.0.1:8000/api').replace(/\/$/, '');

const normalizeIngredientName = (name: string): string => name.trim().toLowerCase();
const normalizeIngredientIcon = (icon: string): string => icon.trim();

export const loadIngredientsArchive = async (): Promise<number> => {
  logger.info('Requesting ingredient archive from ai-service');

  const response = await axios.post(`${AI_SERVICE_API_BASE_URL}/generate-ingredients`, {});

  const archive = ingredientArchiveSchema.parse(response.data);

  const ingredientsByName = new Map<string, string>();
  for (const ingredient of archive) {
    const normalizedName = normalizeIngredientName(ingredient.name);
    if (!normalizedName || ingredientsByName.has(normalizedName)) {
      continue;
    }

    ingredientsByName.set(normalizedName, normalizeIngredientIcon(ingredient.icon));
  }

  const result = await prisma.ingredient.createMany({
    data: Array.from(ingredientsByName.entries()).map(([name, icon]) => ({ name, icon })),
    skipDuplicates: true,
  });

  logger.info(
    `Ingredient archive loaded. Saved ${result.count} new ingredients from ${archive.length} generated records.`,
  );

  return result.count;
};
