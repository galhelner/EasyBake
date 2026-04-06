import 'dotenv/config';
import logger from '../services/logger';
import prisma from '../services/prismaClient';
import { loadIngredientsArchive } from '../services/ingredientArchiveService';

const run = async (): Promise<void> => {
  try {
    const savedCount = await loadIngredientsArchive();
    logger.info(`Ingredient archive import completed successfully. Saved count: ${savedCount}`);
  } catch (error: any) {
    logger.error(`Ingredient archive import failed: ${error?.message ?? 'Unknown error'}`);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
  }
};

void run();
