import dotenv from 'dotenv';
dotenv.config();
import express, { Application } from 'express';
import { json } from 'express';
import { rm } from 'fs/promises';
import { resolve } from 'path';
import authRouter from './routes/auth.routes';
import chatRouter from './routes/chat.routes';
import recipeRouter from './routes/recipe.routes';
import logger from './services/logger';
import cors from 'cors';

const app: Application = express();
const port = process.env.PORT || 4000;

app.use(cors({
  origin: '*', // Allows all origins (fine for development)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(json());

app.use((req, res, next) => {
  const startedAt = Date.now();

  logger.info(`Incoming request: ${req.method} ${req.originalUrl}`);

  res.on('finish', () => {
    const durationMs = Date.now() - startedAt;
    logger.info(`Completed ${req.method} ${req.originalUrl} ${res.statusCode} in ${durationMs}ms`);
  });

  next();
});

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', service: 'recipe-service' });
});

app.use('/auth', authRouter);
app.use('/chat', chatRouter);
app.use('/recipes', recipeRouter);

const cleanupTmpFolder = async (): Promise<void> => {
  const tmpPath = resolve('tmp');
  try {
    await rm(tmpPath, { recursive: true, force: true });
    logger.info(`Cleaned up temporary folder: ${tmpPath}`);
  } catch (error) {
    // eslint-disable-next-line no-console
    console.warn(`Failed to clean up temporary folder: ${error}`);
  }
};

const handleShutdown = async (signal: string): Promise<void> => {
  logger.info(`Received ${signal}, shutting down gracefully...`);
  await cleanupTmpFolder();
  process.exit(0);
};

const server = app.listen(Number(port), "0.0.0.0", () => {
  logger.info(`Recipe service listening on port ${port}`);
});

process.on('SIGTERM', () => handleShutdown('SIGTERM'));
process.on('SIGINT', () => handleShutdown('SIGINT'));

