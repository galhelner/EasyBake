import { Router } from 'express';
import { emailExists, login, register } from '../controllers/auth.controller';

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.get('/email-exists', emailExists);

export default router;

