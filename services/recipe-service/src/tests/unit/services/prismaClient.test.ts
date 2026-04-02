import { afterEach, describe, expect, it, jest } from '@jest/globals';

type PrismaLoadResult = {
	prisma: unknown;
	mockPoolCtor: ReturnType<typeof jest.fn>;
	mockPrismaPgCtor: ReturnType<typeof jest.fn>;
	mockPrismaClientCtor: ReturnType<typeof jest.fn>;
};

async function loadPrismaClientModule(databaseUrl?: string): Promise<PrismaLoadResult> {
	jest.resetModules();

	if (databaseUrl) {
		process.env.DATABASE_URL = databaseUrl;
	} else {
		delete process.env.DATABASE_URL;
	}

	const mockPoolInstance = { id: 'pool-instance' };
	const mockAdapterInstance = { id: 'adapter-instance' };
	const mockPrismaInstance = { id: 'prisma-instance' };

	const mockPoolCtor = jest.fn(() => mockPoolInstance);
	const mockPrismaPgCtor = jest.fn(() => mockAdapterInstance);
	const mockPrismaClientCtor = jest.fn(() => mockPrismaInstance);

	jest.doMock('pg', () => ({
		__esModule: true,
		default: {
			Pool: mockPoolCtor,
		},
	}));

	jest.doMock('@prisma/adapter-pg', () => ({
		PrismaPg: mockPrismaPgCtor,
	}));

	jest.doMock('@prisma/client', () => ({
		PrismaClient: mockPrismaClientCtor,
	}));

	const { default: prisma } = await import('../../../services/prismaClient');

	return {
		prisma,
		mockPoolCtor,
		mockPrismaPgCtor,
		mockPrismaClientCtor,
	};
}

afterEach(() => {
	delete process.env.DATABASE_URL;
	jest.clearAllMocks();
	jest.resetModules();
});

describe('prismaClient service', () => {
	it('throws an error when DATABASE_URL is missing', async () => {
		await expect(import('../../../services/prismaClient')).rejects.toThrow(
			'DATABASE_URL is not defined in environment variables'
		);
	});

	it('creates pg pool, adapter, and prisma client from DATABASE_URL', async () => {
		const dbUrl = 'postgresql://my_user:secret@db.example.com:6543/easy_bake';
		const {
			prisma,
			mockPoolCtor,
			mockPrismaPgCtor,
			mockPrismaClientCtor,
		} = await loadPrismaClientModule(dbUrl);

		expect(prisma).toEqual({ id: 'prisma-instance' });
		expect(mockPoolCtor).toHaveBeenCalledTimes(1);
		expect(mockPoolCtor).toHaveBeenCalledWith({
			user: 'my_user',
			password: 'secret',
			host: 'db.example.com',
			port: 6543,
			database: 'easy_bake',
			ssl: {
				rejectUnauthorized: false,
			},
		});
		expect(mockPrismaPgCtor).toHaveBeenCalledWith({ id: 'pool-instance' });
		expect(mockPrismaClientCtor).toHaveBeenCalledWith({
			adapter: { id: 'adapter-instance' },
		});
	});

	it('decodes escaped password characters from DATABASE_URL', async () => {
		const dbUrl =
			'postgresql://my_user:p%40ss%23word@db.example.com:5432/easy_bake';

		const { mockPoolCtor } = await loadPrismaClientModule(dbUrl);

		expect(mockPoolCtor).toHaveBeenCalledWith(
			expect.objectContaining({
				password: 'p@ss#word',
			})
		);
	});
});
