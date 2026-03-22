import { Response } from 'express';
import { z } from 'zod';
import prisma from '../services/prismaClient';
import { getSupabaseClient } from '../services/supabaseClient';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import logger from '../services/logger';

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

export const register = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  const { email, password } = parsed.data;

  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.signUp({ email, password });

    if (error) {
      res.status(400).json({ error: error.message });
      return;
    }

    const supabaseUser = data.user;
    if (!supabaseUser) {
      // Can happen if sign up is blocked by settings.
      res.status(400).json({ error: 'Signup failed' });
      return;
    }

    await prisma.user.upsert({
      where: { authId: supabaseUser.id },
      update: {},
      create: { authId: supabaseUser.id },
    });

    // Session may be null when email confirmation is required.
    res.status(201).json({
      user: { id: supabaseUser.id, email: supabaseUser.email },
      access_token: data.session?.access_token ?? null,
      refresh_token: data.session?.refresh_token ?? null,
    });
  } catch (err) {
    logger.error(`Register error: ${err instanceof Error ? err.message : String(err)}`);
    res.status(500).json({ error: 'Failed to register' });
  }
};

export const login = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const parsed = loginSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  const { email, password } = parsed.data;

  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error) {
      res.status(401).json({ error: error.message });
      return;
    }

    if (!data.session?.access_token) {
      res.status(401).json({ error: 'Login failed' });
      return;
    }

    const supabaseUserId = data.user?.id;
    if (supabaseUserId) {
      await prisma.user.upsert({
        where: { authId: supabaseUserId },
        update: {},
        create: { authId: supabaseUserId },
      });
    }

    res.status(200).json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      user: data.user ? { id: data.user.id, email: data.user.email } : null,
    });
  } catch (err) {
    logger.error(`Login error: ${err instanceof Error ? err.message : String(err)}`);
    res.status(500).json({ error: 'Failed to login' });
  }
};

