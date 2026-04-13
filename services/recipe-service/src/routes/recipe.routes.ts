import { Router } from 'express';
import multer from 'multer';
import { authMiddleware } from '../middleware/authMiddleware';
import {
  createRecipeFromImage,
  createRecipe,
  deleteRecipe,
  getRecipeById,
  getRecipes,
  searchIngredients,
  searchRecipes,
  updateRecipe,
} from '../controllers/recipe.controller';

const router = Router();
const upload = multer({
  dest: 'tmp/uploads',
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
});

router.use(authMiddleware);

router.post('/', upload.single('image'), createRecipe);
router.post('/create-from-image', upload.single('image'), createRecipeFromImage);
router.post('/search', searchRecipes);
router.get('/ingredients/search', searchIngredients);
router.get('/', getRecipes);
router.put('/:id', upload.single('image'), updateRecipe);
router.delete('/:id', deleteRecipe);
router.get('/:id', getRecipeById);

export default router;

