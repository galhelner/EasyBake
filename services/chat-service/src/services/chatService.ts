import getPrismaClient from './prismaClient';
import logger from './logger';

export interface ChatMessage {
  id: string;
  userId: string;
  userEmail: string;
  userFullName: string | null;
  content: string;
  createdAt: Date;
}

export const saveMessage = async (userId: string, content: string): Promise<ChatMessage> => {
  const prisma = getPrismaClient();

  try {
    const message = await prisma.message.create({
      data: {
        userId,
        content
      },
      include: {
        user: {
          select: {
            id: true,
            email: true,
            fullName: true
          }
        }
      }
    });

    return {
      id: message.id,
      userId: message.user.id,
      userEmail: message.user.email || '',
      userFullName: message.user.fullName,
      content: message.content,
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
            fullName: true
          }
        }
      },
      orderBy: {
        createdAt: 'asc'
      }
    });

    return messages.map((msg: typeof messages[number]): ChatMessage => ({
      id: msg.id,
      userId: msg.user.id,
      userEmail: msg.user.email || '',
      userFullName: msg.user.fullName,
      content: msg.content,
      createdAt: msg.createdAt
    }));
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
