import getPrismaClient from './prismaClient';
import logger from './logger';

export interface ChatMessage {
  id: string;
  userId: string;
  userEmail: string;
  userFullName: string | null;
  userDisplayName: string | null;
  content: string;
  messageType: string;
  recipeId: string | null;
  createdAt: Date;
}

interface SaveMessageInput {
  content: string;
  messageType?: string;
  recipeId?: string | null;
}

export const saveMessage = async (
  userId: string,
  input: SaveMessageInput
): Promise<ChatMessage> => {
  const prisma = getPrismaClient();
  const normalizedType = (input.messageType ?? 'text').trim().toLowerCase();
  const messageType = normalizedType === 'recipe' ? 'recipe' : 'text';

  try {
    const message = await prisma.message.create({
      data: {
        userId,
        content: input.content,
        messageType,
        recipeId: messageType === 'recipe' ? input.recipeId ?? null : null
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            fullName: true,
            displayName: true
          }
        }
      }
    });

    return {
      id: message.id,
      userId: message.user.id,
      userEmail: message.user.email || '',
      userFullName: message.user.fullName,
      userDisplayName: message.user.displayName ?? message.user.fullName,
      content: message.content,
      messageType,
      recipeId: messageType === 'recipe' ? input.recipeId ?? null : null,
      createdAt: message.createdAt
    };
  } catch (error) {
    logger.error('Failed to save message', error);
    throw error;
  }
};

export const getRecentMessages = async (limit: number = 50): Promise<ChatMessage[]> => {
  const prisma = getPrismaClient();

  try {
    const messages = await prisma.message.findMany({
      take: -limit,
      include: {
        user: {
          select: {
            id: true,
            email: true,
            fullName: true,
            displayName: true
          }
        }
      },
      orderBy: {
        createdAt: 'asc'
      }
    });

    return messages.map((msg: typeof messages[number]): ChatMessage => {
      const raw = msg as unknown as Record<string, unknown>;
      const persistedType =
        typeof raw['messageType'] === 'string' && raw['messageType'].toString().trim().length > 0
          ? raw['messageType'] as string
          : 'text';
      const persistedRecipeId =
        typeof raw['recipeId'] === 'string' ? (raw['recipeId'] as string) : null;

      return {
        id: msg.id,
        userId: msg.user.id,
        userEmail: msg.user.email || '',
        userFullName: msg.user.fullName,
        userDisplayName: msg.user.displayName ?? msg.user.fullName,
        content: msg.content,
        messageType: persistedType,
        recipeId: persistedRecipeId,
        createdAt: msg.createdAt
      };
    });
  } catch (error) {
    logger.error('Failed to fetch recent messages', error);
    throw error;
  }
};

export const userExists = async (userId: string): Promise<boolean> => {
  const prisma = getPrismaClient();

  try {
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });
    return !!user;
  } catch (error) {
    logger.error('Failed to check if user exists', error);
    throw error;
  }
};
