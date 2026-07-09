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
  moveRecipe,
} from '../controllers/recipe.controller';
import {
  createFolder,
  getFolders,
  updateFolder,
  deleteFolder,
} from '../controllers/folder.controller';

const router = Router();
const upload = multer({
  dest: 'tmp/uploads',
  limits: {
    fileSize: 10 * 1024 * 1024,
  },
});

router.use(authMiddleware);

// Folder routes (must be declared BEFORE recipe parametric routes)
router.post('/folders', createFolder);
router.get('/folders', getFolders);
router.put('/folders/:id', updateFolder);
router.delete('/folders/:id', deleteFolder);

router.post('/', upload.single('image'), createRecipe);
router.post('/create-from-image', upload.single('image'), createRecipeFromImage);
router.post('/search', searchRecipes);
router.get('/ingredients/search', searchIngredients);
router.get('/', getRecipes);
router.put('/:id/move', moveRecipe);
router.put('/:id', upload.single('image'), updateRecipe);
router.delete('/:id', deleteRecipe);
router.get('/:id', getRecipeById);

export default router;


