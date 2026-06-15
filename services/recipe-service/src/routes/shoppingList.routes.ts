import { Router } from 'express';
import { authMiddleware } from '../middleware/authMiddleware';
import {
  createShoppingListItem,
  deleteShoppingListItem,
  getShoppingList,
  updateShoppingListItem,
} from '../controllers/shoppingList.controller';

const router = Router();

router.use(authMiddleware);

router.get('/', getShoppingList);
router.post('/', createShoppingListItem);
router.patch('/:id', updateShoppingListItem);
router.delete('/:id', deleteShoppingListItem);

export default router;