import { saveMessage, getRecentMessages, userExists } from '../../../services/chatService';
import getPrismaClient from '../../../services/prismaClient';

jest.mock('../../../services/prismaClient');
jest.mock('../../../services/logger');

describe('chatService', () => {
  const mockPrisma = {
    message: {
      create: jest.fn(),
      findMany: jest.fn()
    },
    user: {
      findUnique: jest.fn()
    }
  };

  beforeEach(() => {
    jest.clearAllMocks();
    (getPrismaClient as jest.Mock).mockReturnValue(mockPrisma);
  });

  describe('saveMessage', () => {
    it('should save a message and return it with user details', async () => {
      const userId = 'user-123';
      const content = 'Hello, community!';

      mockPrisma.message.create.mockResolvedValue({
        id: 'msg-1',
        userId,
        content,
        createdAt: new Date(),
        user: {
          id: userId,
          email: 'user@example.com',
          fullName: 'John Doe'
        }
      });

      const result = await saveMessage(userId, content);

      expect(result).toEqual({
        id: 'msg-1',
        userId,
        userEmail: 'user@example.com',
        userFullName: 'John Doe',
        content,
        createdAt: expect.any(Date)
      });

      expect(mockPrisma.message.create).toHaveBeenCalledWith({
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
    });

    it('should throw an error if message save fails', async () => {
      mockPrisma.message.create.mockRejectedValue(new Error('Database error'));

      await expect(saveMessage('user-123', 'Hello')).rejects.toThrow('Database error');
    });
  });

  describe('getRecentMessages', () => {
    it('should return recent messages sorted by creation date', async () => {
      const messages = [
        {
          id: 'msg-1',
          userId: 'user-1',
          content: 'First message',
          createdAt: new Date('2026-04-15T10:00:00Z'),
          user: {
            id: 'user-1',
            email: 'user1@example.com',
            fullName: 'User One'
          }
        },
        {
          id: 'msg-2',
          userId: 'user-2',
          content: 'Second message',
          createdAt: new Date('2026-04-15T10:05:00Z'),
          user: {
            id: 'user-2',
            email: 'user2@example.com',
            fullName: 'User Two'
          }
        }
      ];

      mockPrisma.message.findMany.mockResolvedValue(messages);

      const result = await getRecentMessages(50);

      expect(result).toHaveLength(2);
      expect(result[0].id).toBe('msg-1');
      expect(result[1].id).toBe('msg-2');
    });

    it('should use default limit of 50 if not provided', async () => {
      mockPrisma.message.findMany.mockResolvedValue([]);

      await getRecentMessages();

      expect(mockPrisma.message.findMany).toHaveBeenCalledWith({
        take: -50,
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
    });
  });

  describe('userExists', () => {
    it('should return true if user exists', async () => {
      mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-123' });

      const result = await userExists('user-123');

      expect(result).toBe(true);
    });

    it('should return false if user does not exist', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);

      const result = await userExists('user-123');

      expect(result).toBe(false);
    });
  });
});
