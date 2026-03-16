import { Router } from 'express';
import { streamChat } from '../controllers/chat.controller';
import { authMiddleware } from '../middleware/authMiddleware';

const router = Router();

router.use(authMiddleware);

router.post('/', streamChat);

export default router;