import { afterEach, describe, expect, it, jest } from '@jest/globals';

type ChatControllerModule = {
	streamChat: (req: any, res: any) => Promise<void>;
};

type ChatModuleLoad = {
	controller: ChatControllerModule;
	mockAxiosPost: ReturnType<typeof jest.fn>;
	mockAxiosIsAxiosError: ReturnType<typeof jest.fn>;
	mockPrismaUserFindUnique: ReturnType<typeof jest.fn>;
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
		};
		const res = createMockResponse();

		await controller.streamChat(req, res);

		expect(res.status).toHaveBeenCalledWith(400);
		expect(res.json).toHaveBeenCalledWith(
			expect.objectContaining({ error: 'Validation error' })
		);
		expect(mockAxiosPost).not.toHaveBeenCalled();
	});

	it('returns upstream-friendly error when routing call fails', async () => {
		const { controller, mockAxiosPost, mockAxiosIsAxiosError, mockLoggerError } =
			await loadChatControllerModule();

		mockAxiosIsAxiosError.mockReturnValue(false);
		mockAxiosPost.mockRejectedValue(new Error('router unavailable'));

		const req = {
			method: 'POST',
			originalUrl: '/chat/stream',
			body: { prompt: 'hello', page_context: 'home' },
		};
		const res = createMockResponse();

		await controller.streamChat(req, res);

		expect(mockLoggerError).toHaveBeenCalled();
		expect(res.status).toHaveBeenCalledWith(500);
		expect(res.json).toHaveBeenCalledWith({
			error: 'AI service is temporarily unavailable. Please try again.',
		});
	});

	it('handles CREATE_RECIPE intent and returns generated payload', async () => {
		const { controller, mockAxiosPost } = await loadChatControllerModule();
		const generatedRecipe = {
			title: 'Spicy Lentil Soup',
			instructions: ['Cook lentils', 'Add spices'],
		};

		mockAxiosPost
			.mockResolvedValueOnce({
				data: {
					intent: 'CREATE_RECIPE',
					confidence: 0.99,
				},
			})
			.mockResolvedValueOnce({
				data: generatedRecipe,
			});

		const req = {
			method: 'POST',
			originalUrl: '/chat/stream',
			body: { prompt: 'Create healthy soup', page_context: 'home' },
		};
		const res = createMockResponse();

		await controller.streamChat(req, res);

		expect(mockAxiosPost).toHaveBeenCalledTimes(2);
		expect(res.status).toHaveBeenCalledWith(200);
		expect(res.json).toHaveBeenCalledWith(generatedRecipe);
	});

	it('returns 401 for SEARCH_RECIPES intent when user is unauthenticated', async () => {
		const { controller, mockAxiosPost, mockPrismaUserFindUnique } =
			await loadChatControllerModule();

		mockAxiosPost
			.mockResolvedValueOnce({
				data: {
					intent: 'SEARCH_RECIPES',
					confidence: 0.95,
				},
			})
			.mockResolvedValueOnce({
				data: {
					query: 'high protein breakfast',
				},
			});

		const req = {
			method: 'POST',
			originalUrl: '/chat/stream',
			body: { prompt: 'Find breakfast recipes', page_context: 'home' },
			user: undefined,
		};
		const res = createMockResponse();

		await controller.streamChat(req, res);

		expect(res.status).toHaveBeenCalledWith(401);
		expect(res.json).toHaveBeenCalledWith({ error: 'Unauthorized' });
		expect(mockPrismaUserFindUnique).not.toHaveBeenCalled();
	});
});
