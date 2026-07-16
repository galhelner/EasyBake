import { Router } from 'express';
import {
  streamChat,
  getChatHistory,
  clearChatHistory,
  internalSearchRecipes,
  internalAddToShoppingList,
  internalAddRecipeToShoppingList,
} from '../controllers/chat.controller';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.use(authMiddleware);

router.get('/history', getChatHistory);
router.delete('/history', clearChatHistory);
router.post('/', streamChat);

router.post('/internal/recipes/search', internalSearchRecipes);
router.post('/internal/shopping-list/add', internalAddToShoppingList);
router.post('/internal/shopping-list/add-recipe', internalAddRecipeToShoppingList);

export default router;