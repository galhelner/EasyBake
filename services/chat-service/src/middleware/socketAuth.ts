import { Socket } from 'socket.io';
import { createClient } from '@supabase/supabase-js';
import logger from '../services/logger';
import getPrismaClient from '../services/prismaClient';

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || '';

let supabase: ReturnType<typeof createClient> | null = null;

const getSupabaseClient = () => {
  if (supabase) {
    return supabase;
  }

  if (!supabaseUrl || !supabaseAnonKey) {
    logger.error('Supabase environment variables not configured');
    throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY are required');
  }

  supabase = createClient(supabaseUrl, supabaseAnonKey);
  return supabase;
};

export interface AuthenticatedSocket extends Socket {
  userId?: string;
  userEmail?: string;
}

export interface AuthenticatedUser {
  userId: string;
  userEmail: string;
}

export const authenticateToken = async (token: string): Promise<AuthenticatedUser | null> => {
  try {
    if (!token) {
      return null;
    }

    const client = getSupabaseClient();
    const { data, error } = await client.auth.getUser(token);

    if (error || !data.user) {
      logger.warn(`Token authentication failed`);
      return null;
    }

    const prisma = getPrismaClient();
    const user = await prisma.user.findUnique({
      where: { authId: data.user.id }
    });

    if (!user) {
      logger.warn(`User not found in database for auth email: ${data.user.email}`);
      return null;
    }

    return {
      userId: user.id,
      userEmail: data.user.email || ''
    };
  } catch (error) {
    logger.error('Token authentication error', error);
    return null;
  }
};

export const verifySocketAuth = async (socket: AuthenticatedSocket): Promise<boolean> => {
  try {
    const token = socket.handshake.auth.token as string;

    if (!token) {
      logger.warn('Socket connection attempt without token');
      return false;
    }

    const authenticatedUser = await authenticateToken(token);

    if (!authenticatedUser) {
      return false;
    }

    socket.userId = authenticatedUser.userId;
    socket.userEmail = authenticatedUser.userEmail;

    return true;
  } catch (error) {
    logger.error('Socket auth verification error', error);
    return false;
  }
};
