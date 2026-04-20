import dotenv from 'dotenv';
dotenv.config();
import express, { Application } from 'express';
import { createServer } from 'http';
import { Server, Socket } from 'socket.io';
import logger from './services/logger';
import { authenticateToken, verifySocketAuth, AuthenticatedSocket } from './middleware/socketAuth';
import { saveMessage, getRecentMessages } from './services/chatService';

const app: Application = express();
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
    res.status(200).json(messages);
  } catch (error) {
    logger.error('Failed to fetch chat messages', error);
    res.status(500).json({ message: 'Failed to fetch messages' });
  }
});

const COMMUNITY_ROOM = 'community-chat';

// Socket.IO connection handler
io.on('connection', async (socket: Socket) => {
  const authSocket = socket as AuthenticatedSocket;

  logger.info(`New connection attempt: ${socket.id}`);

  // Verify authentication
  const isAuthenticated = await verifySocketAuth(authSocket);

  if (!isAuthenticated) {
    logger.warn(`Unauthorized connection attempt: ${socket.id}`);
    socket.disconnect(true);
    return;
  }

  logger.info(`User ${authSocket.userId} connected with socket ${socket.id}`);

  // Join the community chat room
  authSocket.join(COMMUNITY_ROOM);
  logger.info(`User ${authSocket.userId} joined ${COMMUNITY_ROOM}`);

  try {
    // Send recent messages to the newly connected user
    const recentMessages = await getRecentMessages(50);
    authSocket.emit('message_history', recentMessages);
    logger.info(`Sent message history to user ${authSocket.userId}`);
  } catch (error) {
    logger.error('Failed to send message history', error);
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

      logger.info(`Message saved from user ${authSocket.userId}: ${savedMessage.id}`);
    } catch (error) {
      logger.error('Failed to save message', error);
      authSocket.emit('error', { message: 'Failed to save message' });
    }
  });

  // Handle disconnection
  authSocket.on('disconnect', () => {
    logger.info(`User ${authSocket.userId} disconnected from socket ${socket.id}`);

    // Notify others that a user left
    io.to(COMMUNITY_ROOM).emit('user_left', {
      userId: authSocket.userId,
      timestamp: new Date()
    });
  });

  // Handle socket errors
  authSocket.on('error', (error: unknown) => {
    logger.error(`Socket error for user ${authSocket.userId}`, error);
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
