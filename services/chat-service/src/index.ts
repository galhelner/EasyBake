import dotenv from 'dotenv';
dotenv.config();
import express, { Application } from 'express';
import { createServer } from 'http';
import { Server, Socket } from 'socket.io';
import logger from './services/logger';
import { authenticateToken, verifySocketAuth, AuthenticatedSocket } from './middleware/socketAuth';
import { saveMessage, getRecentMessages } from './services/chatService';

const app: Application = express();
app.use(express.json());
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST']
  }
});

const port = process.env.PORT || 4001;

// Health check endpoint
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', service: 'chat-service' });
});

app.get('/messages', async (req, res) => {
  try {
    const authHeader = req.header('authorization') || req.header('Authorization');
    const token = authHeader?.startsWith('Bearer ')
      ? authHeader.slice('Bearer '.length).trim()
      : '';

    const authenticatedUser = await authenticateToken(token);

    if (!authenticatedUser) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }

    const limitParam = Number(req.query.limit ?? 50);
    const limit = Number.isFinite(limitParam) && limitParam > 0
      ? Math.min(Math.floor(limitParam), 100)
      : 50;

    const messages = await getRecentMessages(limit);
    logger.info(`📨 ${authenticatedUser.userEmail} fetched ${messages.length} messages`);
    res.status(200).json(messages);
  } catch (error) {
    logger.error('Failed to fetch chat messages', error);
    res.status(500).json({ message: 'Failed to fetch messages' });
  }
});

// Get user profile (displayName, email)
app.get('/profile', async (req, res) => {
  try {
    const authHeader = req.header('authorization') || req.header('Authorization');
    const token = authHeader?.startsWith('Bearer ')
      ? authHeader.slice('Bearer '.length).trim()
      : '';

    const authenticatedUser = await authenticateToken(token);

    if (!authenticatedUser) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }

    const prisma = (await import('./services/prismaClient')).default();

    const user = await prisma.user.findUnique({
      where: { id: authenticatedUser.userId },
      select: { id: true, email: true, displayName: true, fullName: true }
    });

    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    res.status(200).json(user);
  } catch (error) {
    logger.error('Failed to fetch profile', error);
    res.status(500).json({ message: 'Failed to fetch profile' });
  }
});

// Update profile (displayName)
app.patch('/profile', async (req, res) => {
  try {
    const authHeader = req.header('authorization') || req.header('Authorization');
    const token = authHeader?.startsWith('Bearer ')
      ? authHeader.slice('Bearer '.length).trim()
      : '';

    const authenticatedUser = await authenticateToken(token);

    if (!authenticatedUser) {
      res.status(401).json({ message: 'Unauthorized' });
      return;
    }

    const { displayName } = req.body as { displayName?: string };

    if (displayName !== undefined && typeof displayName !== 'string') {
      res.status(400).json({ message: 'Invalid displayName' });
      return;
    }

    const prisma = (await import('./services/prismaClient')).default();

    const updated = await prisma.user.update({
      where: { id: authenticatedUser.userId },
      data: { displayName },
      select: { id: true, displayName: true, email: true }
    });

    logger.info(`📝 ${updated.email} updated display name to: "${displayName}"`);

    // Broadcast the name change to community
    io.to(COMMUNITY_ROOM).emit('user_updated', {
      userId: updated.id,
      displayName: updated.displayName
    });

    res.status(200).json({ success: true, user: updated });
  } catch (error) {
    logger.error('Failed to update profile', error);
    res.status(500).json({ message: 'Failed to update profile' });
  }
});

const COMMUNITY_ROOM = 'community-chat';

// Socket.IO connection handler
io.on('connection', async (socket: Socket) => {
  const authSocket = socket as AuthenticatedSocket;

  // Verify authentication
  const isAuthenticated = await verifySocketAuth(authSocket);

  if (!isAuthenticated) {
    logger.warn(`Unauthorized connection attempt: ${socket.id}`);
    socket.disconnect(true);
    return;
  }

  const userEmail = authSocket.userEmail || 'unknown';
  logger.info(`✓ User connected: ${userEmail}`);

  // Join the community chat room
  authSocket.join(COMMUNITY_ROOM);

  try {
    // Send recent messages to the newly connected user
    const recentMessages = await getRecentMessages(50);
    authSocket.emit('message_history', recentMessages);
  } catch (error) {
    logger.error(`Failed to send message history to ${userEmail}`, error);
    authSocket.emit('error', { message: 'Failed to load message history' });
  }

  // Notify others that a user joined
  io.to(COMMUNITY_ROOM).emit('user_joined', {
    userId: authSocket.userId,
    email: authSocket.userEmail,
    timestamp: new Date()
  });

  // Handle incoming messages
  authSocket.on('send_message', async (data: unknown) => {
    try {
      const messageData = data as Record<string, unknown>;
      const content = messageData.content as string;

      if (!content || typeof content !== 'string') {
        authSocket.emit('error', { message: 'Invalid message content' });
        return;
      }

      const trimmedContent = content.trim();

      if (!trimmedContent || trimmedContent.length === 0) {
        authSocket.emit('error', { message: 'Message cannot be empty' });
        return;
      }

      if (trimmedContent.length > 500) {
        authSocket.emit('error', { message: 'Message is too long (max 500 characters)' });
        return;
      }

      // Save message to database
      const savedMessage = await saveMessage(authSocket.userId as string, trimmedContent);

      // Emit message to all users in the community room
      io.to(COMMUNITY_ROOM).emit('new_message', savedMessage);

      const contentPreview = trimmedContent.length > 50 
        ? `${trimmedContent.substring(0, 50)}...` 
        : trimmedContent;
      logger.info(`💬 Message from ${userEmail}: "${contentPreview}"`);
    } catch (error) {
      logger.error(`Failed to save message from ${userEmail}`, error);
      authSocket.emit('error', { message: 'Failed to save message' });
    }
  });

  // Handle disconnection
  authSocket.on('disconnect', () => {
    logger.info(`✗ User disconnected: ${userEmail}`);

    // Notify others that a user left
    io.to(COMMUNITY_ROOM).emit('user_left', {
      userId: authSocket.userId,
      timestamp: new Date()
    });
  });

  // Handle socket errors
  authSocket.on('error', (error: unknown) => {
    logger.error(`Socket error for ${userEmail}`, error);
  });
});

const handleShutdown = (signal: string): void => {
  logger.info(`Received ${signal}, shutting down gracefully...`);
  io.close();
  httpServer.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
};

httpServer.listen(Number(port), '0.0.0.0', () => {
  logger.info(`Chat service listening on port ${port}`);
});

process.on('SIGTERM', () => handleShutdown('SIGTERM'));
process.on('SIGINT', () => handleShutdown('SIGINT'));

export { io, app };
