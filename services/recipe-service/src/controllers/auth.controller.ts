import { Request, Response } from 'express';
import { z } from 'zod';
import prisma from '../services/prismaClient';
import { getSupabaseClient } from '../services/supabaseClient';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import logger from '../services/logger';

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  fullName: z.string().min(2).max(50),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const emailExistsBodySchema = z.object({
  email: z.string().email(),
});

const normalizeEmail = (email: string): string => email.trim().toLowerCase();

const extractDisplayName = (userMetadata: unknown): string | undefined => {
  if (!userMetadata || typeof userMetadata !== 'object') {
    return undefined;
  }

  const metadata = userMetadata as Record<string, unknown>;
  const displayName = metadata['display_name'];
  if (typeof displayName === 'string' && displayName.trim().length > 0) {
    return displayName.trim();
  }

  const fullName = metadata['fullName'];
  if (typeof fullName === 'string' && fullName.trim().length > 0) {
    return fullName.trim();
  }

  return undefined;
};

export const emailExists = async (req: Request, res: Response): Promise<void> => {
  const parsed = emailExistsBodySchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  const email = normalizeEmail(parsed.data.email);

  try {
    const existingUser = await prisma.user.findUnique({
      where: {
        email,
      },
      select: {
        id: true,
      },
    });

    res.status(200).json({ exists: existingUser != null });
  } catch (err) {
    logger.error(`Email exists check error: ${err instanceof Error ? err.message : String(err)}`);
    res.status(500).json({ error: 'Failed to check email' });
  }
};

export const register = async (req: AuthenticatedRequest, res: Response): Promise<void> => {
  const parsed = registerSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  const normalizedEmail = normalizeEmail(parsed.data.email);
  const { password, fullName } = parsed.data;

  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.signUp({
      email: normalizedEmail,
      password,
      options: {
        data: {
          display_name: fullName,
          fullName,
        },
      },
    });

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

    const normalizedSupabaseEmail = normalizeEmail(
      supabaseUser.email ?? normalizedEmail,
    );

    await prisma.user.upsert({
      where: { authId: supabaseUser.id },
      update: { email: normalizedSupabaseEmail, fullName },
      create: {
        authId: supabaseUser.id,
        email: normalizedSupabaseEmail,
        fullName,
      },
    });

    logger.info(`New user registered: ${fullName} (${normalizedSupabaseEmail})`);

    // Session may be null when email confirmation is required.
    res.status(201).json({
      user: { id: supabaseUser.id, email: supabaseUser.email, fullName },
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

  const normalizedEmail = normalizeEmail(parsed.data.email);
  const { password } = parsed.data;

  try {
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.auth.signInWithPassword({
      email: normalizedEmail,
      password,
    });

    if (error) {
      res.status(401).json({ error: error.message });
      return;
    }

    if (!data.session?.access_token) {
      res.status(401).json({ error: 'Login failed' });
      return;
    }

    const supabaseUserId = data.user?.id;
    let user = null;
    if (supabaseUserId) {
      const synchronizedEmail = normalizeEmail(data.user?.email ?? normalizedEmail);
      const synchronizedFullName = extractDisplayName(data.user?.user_metadata);

      user = await prisma.user.upsert({
        where: { authId: supabaseUserId },
        update: {
          email: synchronizedEmail,
          fullName: synchronizedFullName,
        },
        create: {
          authId: supabaseUserId,
          email: synchronizedEmail,
          fullName: synchronizedFullName,
        },
      });
    }

    res.status(200).json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
      user: user ? { id: user.id, email: user.email, fullName: user.fullName } : null,
    });
  } catch (err) {
    logger.error(`Login error: ${err instanceof Error ? err.message : String(err)}`);
    res.status(500).json({ error: 'Failed to login' });
  }
};

