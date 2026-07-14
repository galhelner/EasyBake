import { afterEach, describe, expect, it, jest } from '@jest/globals';
import { Readable } from 'stream';

type ChatControllerModule = {
	streamChat: (req: any, res: any) => Promise<void>;
	internalSearchRecipes: (req: any, res: any) => Promise<void>;
	internalAddToShoppingList: (req: any, res: any) => Promise<void>;
	internalAddRecipeToShoppingList: (req: any, res: any) => Promise<void>;
};

type ChatModuleLoad = {
	controller: ChatControllerModule;
	mockAxiosPost: ReturnType<typeof jest.fn>;
	mockAxiosIsAxiosError: ReturnType<typeof jest.fn>;
	mockPrismaUserFindUnique: ReturnType<typeof jest.fn>;
	mockPrismaRecipeFindFirst: ReturnType<typeof jest.fn>;
	mockLoggerInfo: ReturnType<typeof jest.fn>;
	mockLoggerError: ReturnType<typeof jest.fn>;
};

const createMockResponse = () => {
	const res = {
		status: jest.fn(),
		json: jest.fn(),
		setHeader: jest.fn(),
		writeHead: jest.fn(),
		write: jest.fn(),
		end: jest.fn(),
		flushHeaders: jest.fn(),
		headersSent: false,
		writableEnded: false,
	};

	res.status.mockReturnValue(res);

	return res;
};

async function loadChatControllerModule(): Promise<ChatModuleLoad> {
	jest.resetModules();

	const mockAxiosPost = jest.fn();
	const mockAxiosIsAxiosError = jest.fn(() => false);

	const mockPrismaUserFindUnique = jest.fn();
	const mockPrismaRecipeFindFirst = jest.fn();
	const mockPrismaRecipeFindMany = jest.fn();
	const mockPrismaChefChatMessageFindMany = jest.fn(() => []);
	const mockPrismaChefChatMessageCreate = jest.fn();
	const mockPrismaQueryRaw = jest.fn();

	const mockLoggerInfo = jest.fn();
	const mockLoggerError = jest.fn();

	jest.doMock('axios', () => ({
		__esModule: true,
		default: {
			post: mockAxiosPost,
			isAxiosError: mockAxiosIsAxiosError,
		},
	}));

	jest.doMock('../../../services/prismaClient', () => ({
		__esModule: true,
		default: {
			user: {
				findUnique: mockPrismaUserFindUnique,
			},
			recipe: {
				findFirst: mockPrismaRecipeFindFirst,
				findMany: mockPrismaRecipeFindMany,
			},
			chefChatMessage: {
				findMany: mockPrismaChefChatMessageFindMany,
				create: mockPrismaChefChatMessageCreate,
			},
			$queryRaw: mockPrismaQueryRaw,
		},
	}));

	jest.doMock('../../../services/logger', () => ({
		__esModule: true,
		default: {
			info: mockLoggerInfo,
			error: mockLoggerError,
		},
	}));

	const controller = (await import('../../../controllers/chat.controller')) as ChatControllerModule;

	return {
		controller,
		mockAxiosPost,
		mockAxiosIsAxiosError,
		mockPrismaUserFindUnique,
		mockPrismaRecipeFindFirst,
		mockLoggerInfo,
		mockLoggerError,
	};
}

afterEach(() => {
	jest.clearAllMocks();
	jest.resetModules();
});

describe('chat controller', () => {
	it('returns 400 on validation error', async () => {
		const { controller, mockAxiosPost } = await loadChatControllerModule();
		const req = {
			method: 'POST',
			originalUrl: '/chat/stream',
			body: { prompt: '', page_context: 'home' },
			headers: {},
		};
		const res = createMockResponse();

		await controller.streamChat(req, res);

		expect(res.status).toHaveBeenCalledWith(400);
		expect(res.json).toHaveBeenCalledWith(
			expect.objectContaining({ error: 'Validation error' })
		);
		expect(mockAxiosPost).not.toHaveBeenCalled();
	});

	it('returns upstream-friendly error when agent call fails', async () => {
		const { controller, mockAxiosPost, mockAxiosIsAxiosError, mockLoggerError, mockPrismaUserFindUnique } =
			await loadChatControllerModule();

		mockAxiosIsAxiosError.mockReturnValue(false);
		mockAxiosPost.mockRejectedValue(new Error('Agent unavailable'));
		mockPrismaUserFindUnique.mockResolvedValue({ id: 'test-user-id' });

		const req = {
			method: 'POST',
			originalUrl: '/chat/stream',
			body: { prompt: 'hello', page_context: 'home', session_id: 'test-session' },
			headers: { authorization: 'Bearer token' },
			user: { id: 'test-user-id' },
		};
		const res = createMockResponse();

		await controller.streamChat(req, res);

		expect(mockLoggerError).toHaveBeenCalled();
		expect(res.status).toHaveBeenCalledWith(500);
		expect(res.json).toHaveBeenCalledWith({
			error: 'AI service is temporarily unavailable. Please try again.',
		});
	});

	it('successfully proxies agent stream', async () => {
		const { controller, mockAxiosPost, mockPrismaUserFindUnique } = await loadChatControllerModule();
		const dummyStream = new Readable();
		dummyStream._read = () => {};

		mockAxiosPost.mockResolvedValueOnce({
			data: dummyStream,
		});
		mockPrismaUserFindUnique.mockResolvedValue({ id: 'test-user-id' });

		const req = {
			method: 'POST',
			originalUrl: '/chat/stream',
			body: { prompt: 'Cook something', page_context: 'home', session_id: 'test-session' },
			headers: { authorization: 'Bearer token' },
			user: { id: 'test-user-id' },
			on: jest.fn(),
		};
		const res = createMockResponse();

		await controller.streamChat(req, res);

		expect(mockAxiosPost).toHaveBeenCalledTimes(1);
		expect(res.writeHead).toHaveBeenCalledWith(
			200,
			expect.objectContaining({
				'Content-Type': 'text/event-stream',
			}),
		);
	});
});
