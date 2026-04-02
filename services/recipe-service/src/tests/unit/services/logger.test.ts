import { afterEach, describe, expect, it, jest } from '@jest/globals';

type LoggerLoadResult = {
	logger: unknown;
	mockExistsSync: ReturnType<typeof jest.fn>;
	mockMkdirSync: ReturnType<typeof jest.fn>;
	mockResolve: ReturnType<typeof jest.fn>;
	mockCreateLogger: ReturnType<typeof jest.fn>;
	mockConsoleTransport: ReturnType<typeof jest.fn>;
	mockFileTransport: ReturnType<typeof jest.fn>;
};

async function loadLoggerModule(options?: {
	logsDirExists?: boolean;
	logLevel?: string;
}): Promise<LoggerLoadResult> {
	const logsDirExists = options?.logsDirExists ?? false;

	if (options?.logLevel) {
		process.env.LOG_LEVEL = options.logLevel;
	} else {
		delete process.env.LOG_LEVEL;
	}

	jest.resetModules();

	const mockExistsSync = jest.fn(() => logsDirExists);
	const mockMkdirSync = jest.fn();
	const mockResolve = jest.fn((...parts: string[]) => parts.join('/'));
	const mockCreateLogger = jest.fn(() => ({ name: 'test-logger' }));
	const mockConsoleTransport = jest.fn((options: unknown) => ({
		type: 'console',
		options,
	}));
	const mockFileTransport = jest.fn((options: unknown) => ({
		type: 'file',
		options,
	}));

	jest.doMock('fs', () => ({
		existsSync: mockExistsSync,
		mkdirSync: mockMkdirSync,
	}));

	jest.doMock('path', () => ({
		resolve: mockResolve,
	}));

	jest.doMock('winston', () => ({
		createLogger: mockCreateLogger,
		format: {
			printf: jest.fn(() => 'printf-format'),
			combine: jest.fn((...formatters: unknown[]) => ({ formatters })),
			timestamp: jest.fn(() => 'timestamp-format'),
			colorize: jest.fn(() => 'colorize-format'),
		},
		transports: {
			Console: mockConsoleTransport,
			File: mockFileTransport,
		},
	}));

	const { default: logger } = await import('../../../services/logger');

	return {
		logger,
		mockExistsSync,
		mockMkdirSync,
		mockResolve,
		mockCreateLogger,
		mockConsoleTransport,
		mockFileTransport,
	};
}

afterEach(() => {
	delete process.env.LOG_LEVEL;
	jest.clearAllMocks();
	jest.resetModules();
});

describe('logger service', () => {
	it('creates logs directory when it does not exist', async () => {
		const { logger, mockExistsSync, mockMkdirSync, mockCreateLogger } =
			await loadLoggerModule({ logsDirExists: false });

		expect(logger).toEqual({ name: 'test-logger' });
		expect(mockExistsSync).toHaveBeenCalledWith(expect.stringContaining('/logs'));
		expect(mockMkdirSync).toHaveBeenCalledWith(
			expect.stringContaining('/logs'),
			{ recursive: true }
		);
		expect(mockCreateLogger).toHaveBeenCalledTimes(1);
	});

	it('does not create logs directory when it already exists', async () => {
		const { mockMkdirSync } = await loadLoggerModule({ logsDirExists: true });

		expect(mockMkdirSync).not.toHaveBeenCalled();
	});

	it('uses LOG_LEVEL from environment and configures console and file transports', async () => {
		const {
			mockCreateLogger,
			mockConsoleTransport,
			mockFileTransport,
			mockResolve,
		} = await loadLoggerModule({ logsDirExists: true, logLevel: 'debug' });

		const loggerConfig = mockCreateLogger.mock.calls[0][0] as {
			level: string;
			transports: unknown[];
		};

		expect(loggerConfig.level).toBe('debug');
		expect(loggerConfig.transports).toHaveLength(2);
		expect(mockConsoleTransport).toHaveBeenCalledTimes(1);
		expect(mockFileTransport).toHaveBeenCalledTimes(1);
		expect(mockResolve).toHaveBeenCalledWith(process.cwd(), 'logs');
		expect(mockResolve).toHaveBeenCalledWith(expect.stringContaining('/logs'), 'recipe-service.log');
	});
});
