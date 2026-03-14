import dotenv from 'dotenv';
dotenv.config();
import express, { Application } from 'express';
import { json } from 'express';
import recipeRouter from './routes/recipe.routes';
import authRouter from './routes/auth.routes';

const app: Application = express();
const port = process.env.PORT || 4000;

app.use(json());

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', service: 'recipe-service' });
});

app.use('/auth', authRouter);
app.use('/recipes', recipeRouter);

app.listen(port, () => {
  // eslint-disable-next-line no-console
  console.log(`Recipe service listening on port ${port}`);
});

