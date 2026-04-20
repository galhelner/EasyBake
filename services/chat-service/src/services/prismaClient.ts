import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import logger from './logger';

let prisma: PrismaClient | null = null;

const getPrismaClient = (): PrismaClient => {
  if (prisma !== null) {
    return prisma;
  }

  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    logger.error('DATABASE_URL environment variable is not set');
    throw new Error('DATABASE_URL is required');
  }

  try {
    // Parse the database URL
    const url = new URL(databaseUrl);

    const pool = new Pool({
      user: url.username,
      password: decodeURIComponent(url.password),
      host: url.hostname,
      port: parseInt(url.port, 10),
      database: url.pathname.split('/')[1],
      ssl: {
        rejectUnauthorized: false
      }
    });

    const adapter = new PrismaPg(pool);
    prisma = new PrismaClient({ adapter });

    logger.info('Prisma client initialized');
    return prisma;
  } catch (error) {
    logger.error('Failed to initialize Prisma client', error);
    throw error;
  }
};

export default getPrismaClient;
