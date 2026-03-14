import { Router } from 'express';
import { authMiddleware } from '../middleware/authMiddleware';
import { createRecipe, getRecipeById, getRecipes } from '../controllers/recipe.controller';

const router = Router();

router.use(authMiddleware);

router.post('/', createRecipe);
router.get('/', getRecipes);
router.get('/:id', getRecipeById);

export default router;

