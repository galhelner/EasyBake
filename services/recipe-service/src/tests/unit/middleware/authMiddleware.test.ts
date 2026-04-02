import { afterEach, describe, expect, it, jest } from '@jest/globals';

type AuthMiddlewareModule = {
	authMiddleware: (req: any, res: any, next: any) => Promise<void>;
};

type AuthMiddlewareLoad = {
	controller: AuthMiddlewareModule;
	mockGetSupabaseClient: ReturnType<typeof jest.fn>;
	mockGetUser: ReturnType<typeof jest.fn>;
};

const createMockResponse = () => {
	const res = {
		status: jest.fn(),
		json: jest.fn(),
	};

	res.status.mockReturnValue(res);

	return res;
};

async function loadAuthMiddlewareModule(options?: {
	getUserError?: unknown;
	user?: { id: string } | null;
}): Promise<AuthMiddlewareLoad> {
	jest.resetModules();

	const mockGetUser = jest.fn(async () => ({
		data: { user: options?.user ?? { id: 'user-1' } },
		error: options?.getUserError ?? null,
	}));

	const mockGetSupabaseClient = jest.fn(() => ({
		auth: {
			getUser: mockGetUser,
		},
	}));

	jest.doMock('../../../services/supabaseClient', () => ({
		getSupabaseClient: mockGetSupabaseClient,
	}));

	const controller = (await import('../../../middleware/authMiddleware')) as AuthMiddlewareModule;

	return {
		controller,
		mockGetSupabaseClient,
		mockGetUser,
	};
}

afterEach(() => {
	jest.clearAllMocks();
	jest.resetModules();
});

describe('authMiddleware', () => {
	it('returns 401 when Authorization header is missing', async () => {
		const { controller, mockGetSupabaseClient } = await loadAuthMiddlewareModule();
		const req = { headers: {} };
		const res = createMockResponse();
		const next = jest.fn();

		await controller.authMiddleware(req, res, next);

		expect(res.status).toHaveBeenCalledWith(401);
		expect(res.json).toHaveBeenCalledWith({ error: 'Missing or invalid Authorization header' });
		expect(mockGetSupabaseClient).not.toHaveBeenCalled();
		expect(next).not.toHaveBeenCalled();
	});

	it('returns 401 when Authorization header is invalid', async () => {
		const { controller, mockGetSupabaseClient } = await loadAuthMiddlewareModule();
		const req = { headers: { authorization: 'Token abc123' } };
		const res = createMockResponse();
		const next = jest.fn();

		await controller.authMiddleware(req, res, next);

		expect(res.status).toHaveBeenCalledWith(401);
		expect(res.json).toHaveBeenCalledWith({ error: 'Missing or invalid Authorization header' });
		expect(mockGetSupabaseClient).not.toHaveBeenCalled();
		expect(next).not.toHaveBeenCalled();
	});

	it('returns 401 when token is invalid or expired', async () => {
		const { controller, mockGetUser } = await loadAuthMiddlewareModule({
			getUserError: { message: 'invalid token' },
			user: null,
		});
		const req = { headers: { authorization: 'Bearer test-token' } };
		const res = createMockResponse();
		const next = jest.fn();

		await controller.authMiddleware(req, res, next);

		expect(mockGetUser).toHaveBeenCalledWith('test-token');
		expect(res.status).toHaveBeenCalledWith(401);
		expect(res.json).toHaveBeenCalledWith({ error: 'Invalid or expired token' });
		expect(next).not.toHaveBeenCalled();
	});

	it('attaches the user id and calls next on success', async () => {
		const { controller, mockGetUser } = await loadAuthMiddlewareModule({
			user: { id: 'user-123' },
		});
		const req: any = { headers: { authorization: 'Bearer valid-token' } };
		const res = createMockResponse();
		const next = jest.fn();

		await controller.authMiddleware(req, res, next);

		expect(mockGetUser).toHaveBeenCalledWith('valid-token');
		expect(req.user).toEqual({ id: 'user-123' });
		expect(next).toHaveBeenCalledTimes(1);
	});

	it('returns 500 when Supabase client throws', async () => {
		jest.resetModules();

		jest.doMock('../../../services/supabaseClient', () => ({
			getSupabaseClient: jest.fn(() => ({
				auth: {
					getUser: jest.fn(async () => {
						throw new Error('boom');
					}),
				},
			})),
		}));

		const controller = (await import('../../../middleware/authMiddleware')) as AuthMiddlewareModule;
		const req = { headers: { authorization: 'Bearer valid-token' } };
		const res = createMockResponse();
		const next = jest.fn();
		const consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation(() => undefined);

		await controller.authMiddleware(req, res, next);

		expect(res.status).toHaveBeenCalledWith(500);
		expect(res.json).toHaveBeenCalledWith({ error: 'Authentication failed' });
		expect(next).not.toHaveBeenCalled();
		expect(consoleErrorSpy).toHaveBeenCalled();

		consoleErrorSpy.mockRestore();
	});
});
