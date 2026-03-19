import axios from 'axios';
import { Response } from 'express';
import { Readable } from 'stream';
import { z } from 'zod';
import { AuthenticatedRequest } from '../middleware/authMiddleware';
import prisma from '../services/prismaClient';

const chatRequestSchema = z
  .object({
    prompt: z.string().min(1),
    page_context: z.enum(['home', 'recipe_detail']),
    recipe_id: z.string().min(1).optional(),
  })
  .superRefine((value, ctx) => {
    if (value.page_context === 'recipe_detail' && !value.recipe_id) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ['recipe_id'],
        message: 'recipe_id is required when page_context is recipe_detail',
      });
    }
  });

type RouterIntent =
  | 'CREATE_RECIPE'
  | 'SEARCH_RECIPES'
  | 'HEALTH_AUDIT'
  | 'ASSISTANT_HELP'
  | 'GENERAL_CHAT';

interface RouterResponsePayload {
  intent: RouterIntent;
  confidence: number;
}

interface FlushableResponse extends Response {
  flush?: () => void;
}

interface RecipeContextPayload {
  id: string;
  title: string;
  instructions: string[];
  ingredients: Array<{
    ingredient: {
      name: string;
    };
  }>;
}

const AI_SERVICE_BASE_URL = (process.env.AI_SERVICE_URL ?? 'http://127.0.0.1:8000').replace(/\/$/, '');

const buildRecipeContext = (recipe: RecipeContextPayload): string => {
  const ingredients = recipe.ingredients.length
    ? recipe.ingredients.map(({ ingredient }) => `- ${ingredient.name}`).join('\n')
    : '- No ingredients listed';

  const instructions = recipe.instructions.length
    ? recipe.instructions.map((step, index) => `${index + 1}. ${step}`).join('\n')
    : '- No instruction steps listed';

  return [
    `Recipe title: ${recipe.title}`,
    'Ingredients:',
    ingredients,
    'Instructions:',
    instructions,
  ].join('\n');
};

const loadRecipeContext = async (
  req: AuthenticatedRequest,
  recipeId: string,
): Promise<string | null> => {
  if (!req.user?.id) {
    return null;
  }

  const recipe = await prisma.recipe.findFirst({
    where: {
      id: recipeId,
      author: {
        authId: req.user.id,
      },
    },
    include: {
      ingredients: {
        include: {
          ingredient: true,
        },
      },
    },
  });

  if (!recipe) {
    return null;
  }

  return buildRecipeContext(recipe as RecipeContextPayload);
};

const getAxiosErrorMessage = (error: unknown): string => {
  if (axios.isAxiosError(error)) {
    const data = error.response?.data;

    if (typeof data === 'string' && data.trim().length > 0) {
      return data;
    }

    if (data && typeof data === 'object' && 'detail' in data) {
      const detail = (data as { detail?: unknown }).detail;
      if (typeof detail === 'string' && detail.trim().length > 0) {
        return detail;
      }
    }

    return error.message;
  }

  if (error instanceof Error) {
    return error.message;
  }

  return 'Unknown error';
};

const getAxiosStatusCode = (error: unknown, fallbackStatus = 500): number => {
  if (axios.isAxiosError(error) && error.response?.status) {
    return error.response.status;
  }

  return fallbackStatus;
};

const getInitFailureStatusCode = (error: unknown): number => {
  const upstreamStatus = getAxiosStatusCode(error);
  return upstreamStatus === 429 ? 429 : 500;
};

const getAxiosRetryAfter = (error: unknown): string | null => {
  if (!axios.isAxiosError(error)) {
    return null;
  }

  const retryAfter = error.response?.headers?.['retry-after'];
  if (typeof retryAfter === 'string' && retryAfter.trim().length > 0) {
    return retryAfter;
  }

  return null;
};

const parseRetryAfterSeconds = (
  rawMessage: string,
  retryAfterHeader: string | null,
): number | null => {
  if (retryAfterHeader) {
    const fromHeader = Number.parseInt(retryAfterHeader, 10);
    if (Number.isFinite(fromHeader) && fromHeader > 0) {
      return fromHeader;
    }
  }

  const retryInMatch = rawMessage.match(/retry in\s+([0-9]+(?:\.[0-9]+)?)s/i);
  if (retryInMatch) {
    return Math.max(1, Math.round(Number.parseFloat(retryInMatch[1])));
  }

  const retryDelayMatch = rawMessage.match(/retryDelay[^0-9]*([0-9]+)s/i);
  if (retryDelayMatch) {
    return Math.max(1, Number.parseInt(retryDelayMatch[1], 10));
  }

  return null;
};

const getFriendlyAiErrorMessage = (
  rawMessage: string,
  retryAfterHeader: string | null = null,
): string => {
  const normalized = rawMessage.toLowerCase();
  const isRateLimited =
    normalized.includes('resource_exhausted')
    || normalized.includes('quota')
    || normalized.includes('rate limit')
    || normalized.includes('429');

  if (isRateLimited) {
    const retryAfterSeconds = parseRetryAfterSeconds(rawMessage, retryAfterHeader);
    if (retryAfterSeconds) {
      return `Rate limit reached, please try again in ${retryAfterSeconds} seconds.`;
    }
    return 'Rate limit reached, please try again shortly.';
  }

  return 'AI service is temporarily unavailable. Please try again.';
};

const getUserFacingAxiosErrorMessage = (error: unknown): string => {
  const rawMessage = getAxiosErrorMessage(error);
  const retryAfter = getAxiosRetryAfter(error);
  return getFriendlyAiErrorMessage(rawMessage, retryAfter);
};

const logAxiosFailure = (label: string, error: unknown): void => {
  // eslint-disable-next-line no-console
  console.error(label, {
    status: getAxiosStatusCode(error),
    retryAfter: getAxiosRetryAfter(error),
    detail: getAxiosErrorMessage(error),
  });
};

const sendInitFailureJson = (
  res: Response,
  error: unknown,
  intent: RouterIntent,
): void => {
  const statusCode = getInitFailureStatusCode(error);
  const retryAfter = getAxiosRetryAfter(error);
  if (retryAfter) {
    res.setHeader('Retry-After', retryAfter);
  }

  res.status(statusCode).json({
    error: getUserFacingAxiosErrorMessage(error),
    intent,
  });
};

const writeSseDelta = (res: FlushableResponse, content: string): void => {
  if (!content) {
    return;
  }

  res.write(`data: ${JSON.stringify({ delta: content })}\n\n`);
  res.flush?.();
};

const forwardSseStream = (
  req: AuthenticatedRequest,
  res: FlushableResponse,
  upstreamStream: Readable,
  onAbort: () => void,
): void => {
  let streamClosed = false;

  const closeStream = (): void => {
    if (streamClosed) {
      return;
    }

    streamClosed = true;
    if (!res.writableEnded) {
      res.end();
    }
  };

  req.on('close', () => {
    onAbort();
    if (!upstreamStream.destroyed) {
      upstreamStream.destroy();
    }
    closeStream();
  });

  upstreamStream.on('data', (chunk: Buffer | string) => {
    try {
      const chunkText = chunk.toString();
      if (!chunkText) {
        return;
      }

      writeSseDelta(res, chunkText);
    } catch (streamParseError) {
      // eslint-disable-next-line no-console
      console.error('AI stream parse failed', streamParseError);
      onAbort();
      closeStream();
    }
  });

  upstreamStream.on('end', () => {
    // eslint-disable-next-line no-console
    console.log('AI stream completed');
    closeStream();
  });

  upstreamStream.on('error', (streamError: Error) => {
    // eslint-disable-next-line no-console
    console.error('AI upstream stream failed', streamError);
    onAbort();

    if (!res.writableEnded) {
      writeSseDelta(res, 'AI stream interrupted. Please try again.');
    }

    closeStream();
  });
};

export const streamChat = async (
  req: AuthenticatedRequest,
  res: Response,
): Promise<void> => {
  const parsed = chatRequestSchema.safeParse(req.body);

  if (!parsed.success) {
    res.status(400).json({ error: 'Validation error', details: parsed.error.flatten() });
    return;
  }

  const { prompt, page_context, recipe_id } = parsed.data;

  let recipeContext: string | null = null;
  if (page_context === 'recipe_detail' && recipe_id) {
    try {
      recipeContext = await loadRecipeContext(req, recipe_id);
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('Failed to load recipe context', { recipeId: recipe_id, error });
      res.status(500).json({ error: 'Failed to load recipe context' });
      return;
    }

    if (!recipeContext) {
      res.status(404).json({ error: 'Recipe not found' });
      return;
    }
  }

  let routedIntent: RouterResponsePayload;
  try {
    // eslint-disable-next-line no-console
    console.log('AI route request', { page_context, hasRecipeContext: Boolean(recipeContext) });
    const routeResponse = await axios.post<RouterResponsePayload>(
      `${AI_SERVICE_BASE_URL}/api/route`,
      { prompt, page_context, recipe_context: recipeContext },
      {
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: 30000,
      },
    );

    routedIntent = routeResponse.data;
    // eslint-disable-next-line no-console
    console.log('AI route response', routedIntent);
  } catch (error) {
    logAxiosFailure('AI router request failed', error);

    const statusCode = getAxiosStatusCode(error);
    const retryAfter = getAxiosRetryAfter(error);
    if (retryAfter) {
      res.setHeader('Retry-After', retryAfter);
    }

    res.status(statusCode).json({
      error: getUserFacingAxiosErrorMessage(error),
    });
    return;
  }

  const streamFromAi = async (endpoint: string): Promise<void> => {
    const streamingResponse = res as FlushableResponse;
    const upstreamAbortController = new AbortController();
    const initializeGeminiStream = async (): Promise<Readable | null> => {
      try {
        // eslint-disable-next-line no-console
        console.log('AI stream request', { intent: routedIntent.intent, endpoint });
        const upstreamResponse = await axios.post(
          `${AI_SERVICE_BASE_URL}${endpoint}`,
          { prompt, recipe_context: recipeContext },
          {
            headers: {
              Accept: 'text/event-stream',
              'Content-Type': 'application/json',
            },
            responseType: 'stream',
            signal: upstreamAbortController.signal,
            timeout: 0,
          },
        );

        return upstreamResponse.data as Readable;
      } catch (error) {
        logAxiosFailure('AI stream initialization failed', error);
        sendInitFailureJson(res, error, routedIntent.intent);
        return null;
      }
    };

    const upstreamStream = await initializeGeminiStream();
    if (!upstreamStream) {
      return;
    }

    try {
      streamingResponse.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
        'X-Accel-Buffering': 'no',
      });
      streamingResponse.flushHeaders();

      forwardSseStream(req, streamingResponse, upstreamStream, () => {
        upstreamAbortController.abort();
      });
    } catch (error) {
      // eslint-disable-next-line no-console
      console.error('AI stream setup failed after initialization', error);
      if (!streamingResponse.headersSent) {
        sendInitFailureJson(streamingResponse, error, routedIntent.intent);
      } else if (!streamingResponse.writableEnded) {
        writeSseDelta(streamingResponse, 'AI stream interrupted. Please try again.');
        streamingResponse.end();
      }
    }
  };

  switch (routedIntent.intent) {
    case 'ASSISTANT_HELP':
    case 'GENERAL_CHAT':
      await streamFromAi('/api/stream-assistant');
      return;
    case 'HEALTH_AUDIT':
      await streamFromAi('/api/stream-health');
      return;
    case 'CREATE_RECIPE': {
      try {
        // eslint-disable-next-line no-console
        console.log('AI recipe generation request', { hasRecipeContext: Boolean(recipeContext) });
        const recipeResponse = await axios.post(
          `${AI_SERVICE_BASE_URL}/api/generate-recipe`,
          { prompt, recipe_context: recipeContext },
          {
            headers: {
              'Content-Type': 'application/json',
            },
            timeout: 60000,
          },
        );
        res.status(200).json(recipeResponse.data);
      } catch (error) {
        logAxiosFailure('AI recipe generation failed', error);

        const statusCode = getAxiosStatusCode(error);
        const retryAfter = getAxiosRetryAfter(error);
        if (retryAfter) {
          res.setHeader('Retry-After', retryAfter);
        }

        res.status(statusCode).json({
          error: getUserFacingAxiosErrorMessage(error),
        });
      }
      return;
    }
    case 'SEARCH_RECIPES': {
      try {
        // eslint-disable-next-line no-console
        console.log('AI search-specialist request');
        const searchResponse = await axios.post(
          `${AI_SERVICE_BASE_URL}/api/search-specialist`,
          { prompt, recipe_context: recipeContext },
          {
            headers: {
              'Content-Type': 'application/json',
            },
            timeout: 30000,
          },
        );

        res.status(200).json({
          intent: routedIntent.intent,
          confidence: routedIntent.confidence,
          search: searchResponse.data,
        });
      } catch (error) {
        logAxiosFailure('AI search-specialist call failed', error);

        const statusCode = getAxiosStatusCode(error);
        const retryAfter = getAxiosRetryAfter(error);
        if (retryAfter) {
          res.setHeader('Retry-After', retryAfter);
        }

        res.status(statusCode).json({
          error: getUserFacingAxiosErrorMessage(error),
        });
      }
      return;
    }
    default:
      res.status(400).json({ error: `Unsupported intent: ${routedIntent.intent}` });
  }
};