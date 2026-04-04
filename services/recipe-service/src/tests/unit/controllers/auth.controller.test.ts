import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';

type MockResponse = {
	status: ReturnType<typeof jest.fn>;
	json: ReturnType<typeof jest.fn>;
};

type AuthControllerModule = {
	register: (req: any, res: any) => Promise<void>;
	login: (req: any, res: any) => Promise<void>;
	emailExists: (req: any, res: any) => Promise<void>;
};

type AuthModuleLoad = {
	controller: AuthControllerModule;
	mockGetSupabaseClient: ReturnType<typeof jest.fn>;
	mockSignUp: ReturnType<typeof jest.fn>;
	mockUpdateUser: ReturnType<typeof jest.fn>;
	mockSignInWithPassword: ReturnType<typeof jest.fn>;
	mockPrismaUpsert: ReturnType<typeof jest.fn>;
	mockPrismaFindUnique: ReturnType<typeof jest.fn>;
	mockLoggerInfo: ReturnType<typeof jest.fn>;
	mockLoggerError: ReturnType<typeof jest.fn>;
};

const createMockResponse = (): MockResponse => {
	const res = {
		status: jest.fn(),
		json: jest.fn(),
	};

	res.status.mockReturnValue(res);

	return res;
};

async function loadAuthControllerModule(): Promise<AuthModuleLoad> {
	jest.resetModules();

	const mockSignUp = jest.fn();
	const mockUpdateUser = jest.fn();
	const mockSignInWithPassword = jest.fn();

	const mockGetSupabaseClient = jest.fn(() => ({
		auth: {
			signUp: mockSignUp,
			updateUser: mockUpdateUser,
			signInWithPassword: mockSignInWithPassword,
		},
	}));

	const mockPrismaUpsert = jest.fn();
	const mockPrismaFindUnique = jest.fn();
	const mockLoggerInfo = jest.fn();
	const mockLoggerError = jest.fn();

	jest.doMock('../../../services/supabaseClient', () => ({
		getSupabaseClient: mockGetSupabaseClient,
	}));

	jest.doMock('../../../services/prismaClient', () => ({
		__esModule: true,
		default: {
			user: {
				upsert: mockPrismaUpsert,
				findUnique: mockPrismaFindUnique,
			},
		},
	}));

	jest.doMock('../../../services/logger', () => ({
		__esModule: true,
		default: {
			info: mockLoggerInfo,
			error: mockLoggerError,
		},
	}));

	const controller = (await import('../../../controllers/auth.controller')) as AuthControllerModule;

	return {
		controller,
		mockGetSupabaseClient,
		mockSignUp,
		mockUpdateUser,
		mockSignInWithPassword,
		mockPrismaUpsert,
		mockPrismaFindUnique,
		mockLoggerInfo,
		mockLoggerError,
	};
}

beforeEach(() => {
	jest.restoreAllMocks();
});

afterEach(() => {
	jest.clearAllMocks();
	jest.resetModules();
});

describe('auth controller', () => {
	it('register returns 400 on validation error', async () => {
		const { controller, mockGetSupabaseClient } = await loadAuthControllerModule();
		const req = { body: { email: 'not-an-email', password: '123', fullName: '' } };
		const res = createMockResponse();

		await controller.register(req, res);

		expect(res.status).toHaveBeenCalledWith(400);
		expect(res.json).toHaveBeenCalledWith(
			expect.objectContaining({ error: 'Validation error' })
		);
		expect(mockGetSupabaseClient).not.toHaveBeenCalled();
	});

	it('register returns 201 and user payload on success', async () => {
		const {
			controller,
			mockSignUp,
			mockUpdateUser,
			mockPrismaUpsert,
			mockLoggerInfo,
		} = await loadAuthControllerModule();

		mockSignUp.mockResolvedValue({
			data: {
				user: { id: 'auth-1', email: 'user@example.com' },
				session: { access_token: 'access-1', refresh_token: 'refresh-1' },
			},
			error: null,
		});
		mockPrismaUpsert.mockResolvedValue({
			id: 'db-1',
			authId: 'auth-1',
			email: 'user@example.com',
			fullName: 'John Doe',
		});

		const req = {
			body: { email: 'user@example.com', password: 'password123', fullName: 'John Doe' },
		};
		const res = createMockResponse();

		await controller.register(req, res);

		expect(mockSignUp).toHaveBeenCalledWith({
			email: 'user@example.com',
			password: 'password123',
			options: {
				data: {
					display_name: 'John Doe',
					fullName: 'John Doe',
				},
			},
		});
		expect(mockUpdateUser).not.toHaveBeenCalled();
		expect(mockPrismaUpsert).toHaveBeenCalledWith({
			where: { authId: 'auth-1' },
			update: {
				email: 'user@example.com',
				fullName: 'John Doe',
			},
			create: {
				authId: 'auth-1',
				email: 'user@example.com',
				fullName: 'John Doe',
			},
		});
		expect(mockLoggerInfo).toHaveBeenCalledWith('New user registered: John Doe (user@example.com)');
		expect(res.status).toHaveBeenCalledWith(201);
		expect(res.json).toHaveBeenCalledWith({
			user: { id: 'auth-1', email: 'user@example.com', fullName: 'John Doe' },
			access_token: 'access-1',
			refresh_token: 'refresh-1',
		});
	});

	it('register returns 400 when sign up returns an error', async () => {
		const { controller, mockSignUp } = await loadAuthControllerModule();
		mockSignUp.mockResolvedValue({
			data: { user: null, session: null },
			error: { message: 'Email already registered' },
		});

		const req = {
			body: { email: 'user@example.com', password: 'password123', fullName: 'John Doe' },
		};
		const res = createMockResponse();

		await controller.register(req, res);

		expect(res.status).toHaveBeenCalledWith(400);
		expect(res.json).toHaveBeenCalledWith({ error: 'Email already registered' });
	});

	it('login returns 400 on validation error', async () => {
		const { controller, mockSignInWithPassword } = await loadAuthControllerModule();
		const req = { body: { email: 'invalid-email', password: '' } };
		const res = createMockResponse();

		await controller.login(req, res);

		expect(res.status).toHaveBeenCalledWith(400);
		expect(res.json).toHaveBeenCalledWith(
			expect.objectContaining({ error: 'Validation error' })
		);
		expect(mockSignInWithPassword).not.toHaveBeenCalled();
	});

	it('login returns 401 when supabase rejects credentials', async () => {
		const { controller, mockSignInWithPassword } = await loadAuthControllerModule();
		mockSignInWithPassword.mockResolvedValue({
			data: { user: null, session: null },
			error: { message: 'Invalid login credentials' },
		});

		const req = { body: { email: 'user@example.com', password: 'wrong-password' } };
		const res = createMockResponse();

		await controller.login(req, res);

		expect(res.status).toHaveBeenCalledWith(401);
		expect(res.json).toHaveBeenCalledWith({ error: 'Invalid login credentials' });
	});

	it('login returns 200 with tokens and mapped user on success', async () => {
		const { controller, mockSignInWithPassword, mockPrismaUpsert } = await loadAuthControllerModule();

		mockSignInWithPassword.mockResolvedValue({
			data: {
				user: { id: 'auth-2', email: 'chef@example.com' },
				session: { access_token: 'access-2', refresh_token: 'refresh-2' },
			},
			error: null,
		});
		mockPrismaUpsert.mockResolvedValue({
			id: 'db-2',
			email: 'chef@example.com',
			fullName: 'Chef User',
		});

		const req = { body: { email: 'chef@example.com', password: 'password123' } };
		const res = createMockResponse();

		await controller.login(req, res);

		expect(mockPrismaUpsert).toHaveBeenCalledWith({
			where: { authId: 'auth-2' },
			update: {
				email: 'chef@example.com',
				fullName: undefined,
			},
			create: {
				authId: 'auth-2',
				email: 'chef@example.com',
				fullName: undefined,
			},
		});
		expect(res.status).toHaveBeenCalledWith(200);
		expect(res.json).toHaveBeenCalledWith({
			access_token: 'access-2',
			refresh_token: 'refresh-2',
			user: {
				id: 'db-2',
				email: 'chef@example.com',
				fullName: 'Chef User',
			},
		});
	});

	it('emailExists returns 400 on invalid email', async () => {
		const { controller, mockPrismaFindUnique } = await loadAuthControllerModule();
		const req = { body: { email: 'invalid-email' } };
		const res = createMockResponse();

		await controller.emailExists(req, res);

		expect(res.status).toHaveBeenCalledWith(400);
		expect(res.json).toHaveBeenCalledWith(
			expect.objectContaining({ error: 'Validation error' })
		);
		expect(mockPrismaFindUnique).not.toHaveBeenCalled();
	});

	it('emailExists returns true when email is found', async () => {
		const { controller, mockPrismaFindUnique } = await loadAuthControllerModule();
		mockPrismaFindUnique.mockResolvedValue({ id: 'db-1' });

		const req = { body: { email: 'user@example.com' } };
		const res = createMockResponse();

		await controller.emailExists(req, res);

		expect(mockPrismaFindUnique).toHaveBeenCalledWith({
			where: {
				email: 'user@example.com',
			},
			select: {
				id: true,
			},
		});
		expect(res.status).toHaveBeenCalledWith(200);
		expect(res.json).toHaveBeenCalledWith({ exists: true });
	});

	it('emailExists returns false when email is not found', async () => {
		const { controller, mockPrismaFindUnique } = await loadAuthControllerModule();
		mockPrismaFindUnique.mockResolvedValue(null);

		const req = { body: { email: 'new@example.com' } };
		const res = createMockResponse();

		await controller.emailExists(req, res);

		expect(res.status).toHaveBeenCalledWith(200);
		expect(res.json).toHaveBeenCalledWith({ exists: false });
	});
});
