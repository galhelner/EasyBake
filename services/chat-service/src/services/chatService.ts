import getPrismaClient from './prismaClient';
import logger from './logger';

const AI_CHEF_USER_ID = 'ai-chef';
const AI_CHEF_AUTH_ID = 'system:ai-chef';
const AI_SERVICE_API_BASE_URL = (process.env.AI_SERVICE_URL ?? 'http://127.0.0.1:8000/api').replace(/\/$/, '');
const AI_SERVICE_REQUEST_TIMEOUT_MS = Number(process.env.AI_SERVICE_REQUEST_TIMEOUT_MS ?? 15000);

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
  const messageType = normalizedType === 'recipe'
    ? 'recipe'
    : normalizedType === 'ai-assistant'
      ? 'ai-assistant'
      : 'text';
  const authorUserId = messageType === 'ai-assistant' ? AI_CHEF_USER_ID : userId;

  if (messageType === 'ai-assistant') {
    await prisma.user.upsert({
      where: { id: AI_CHEF_USER_ID },
      create: {
        id: AI_CHEF_USER_ID,
        authId: AI_CHEF_AUTH_ID,
        email: 'ai-chef@easybake.local',
        fullName: 'AI Chef',
        displayName: 'AI Chef'
      },
      update: {
        authId: AI_CHEF_AUTH_ID,
        email: 'ai-chef@easybake.local',
        fullName: 'AI Chef',
        displayName: 'AI Chef'
      }
    });
  }

  try {
    const message = await prisma.message.create({
      data: {
        userId: authorUserId,
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

export const generateAssistantReply = async (prompt: string): Promise<string> => {
  const normalizedPrompt = prompt.trim();
  if (!normalizedPrompt) {
    throw new Error('Prompt cannot be empty');
  }

  const abortController = new AbortController();
  const timeoutId = setTimeout(
    () => abortController.abort(),
    AI_SERVICE_REQUEST_TIMEOUT_MS,
  );

  try {
    const response = await fetch(`${AI_SERVICE_API_BASE_URL}/stream-assistant`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Accept: 'text/event-stream'
      },
      body: JSON.stringify({ prompt: normalizedPrompt }),
      signal: abortController.signal
    });
    if (!response.ok || !response.body) {
      throw new Error(`AI assistant request failed with status ${response.status}`);
    }

    const text = await response.text();
    let answer = '';

    for (const block of text.split(/\n\n+/)) {
      const trimmedBlock = block.trim();
      if (!trimmedBlock.startsWith('data: ')) {
        continue;
      }

      const payloadText = trimmedBlock.slice('data: '.length).trim();
      if (payloadText === '[DONE]') {
        continue;
      }

      try {
        const parsed = JSON.parse(payloadText) as { delta?: string; type?: string };
        if (parsed.type === 'text' && typeof parsed.delta === 'string') {
          answer += parsed.delta;
        }
      } catch {
        continue;
      }
    }

    return answer.trim();
  } catch (error) {
    if ((error as Error).name === 'AbortError') {
      throw new Error(`AI service request timed out after ${AI_SERVICE_REQUEST_TIMEOUT_MS}ms`);
    }

    throw new Error(
      `Failed to reach AI service at ${AI_SERVICE_API_BASE_URL}: ${(error as Error).message}`,
    );
  } finally {
    clearTimeout(timeoutId);
  }
};
