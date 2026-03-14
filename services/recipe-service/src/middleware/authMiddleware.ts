import { NextFunction, Request, Response } from 'express';
import { getSupabaseClient } from '../services/supabaseClient';

export interface AuthenticatedRequest extends Request {
  user?: {
    id: string;
  };
}

export const authMiddleware = async (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
): Promise<void> => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid Authorization header' });
    return;
  }

  const token = authHeader.replace('Bearer ', '').trim();

  try {
    const client = getSupabaseClient();
    const {
      data: { user },
      error,
    } = await client.auth.getUser(token);

    if (error || !user) {
      res.status(401).json({ error: 'Invalid or expired token' });
      return;
    }

    req.user = { id: user.id };
    next();
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error('Auth middleware error', err);
    res.status(500).json({ error: 'Authentication failed' });
  }
};

