import { Router } from 'express';
import multer from 'multer';
import { authMiddleware } from '../middleware/authMiddleware';
import { createRecipe, getRecipeById, getRecipes } from '../controllers/recipe.controller';

const router = Router();
const upload = multer({
  dest: 'tmp/uploads',
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
});

router.use(authMiddleware);

router.post('/', upload.single('image'), createRecipe);
router.get('/', getRecipes);
router.get('/:id', getRecipeById);

export default router;

