import { afterEach, describe, expect, it, jest } from '@jest/globals';

type SupabaseModuleLoadResult = {
	getSupabaseClient: () => unknown;
	mockCreateClient: ReturnType<typeof jest.fn>;
};

async function loadSupabaseClientModule(options?: {
	url?: string;
	anonKey?: string;
}): Promise<SupabaseModuleLoadResult> {
	jest.resetModules();

	if (options?.url) {
		process.env.SUPABASE_URL = options.url;
	} else {
		delete process.env.SUPABASE_URL;
	}

	if (options?.anonKey) {
		process.env.SUPABASE_ANON_KEY = options.anonKey;
	} else {
		delete process.env.SUPABASE_ANON_KEY;
	}

	const mockCreateClient = jest.fn(() => ({ id: 'supabase-client' }));

	jest.doMock('@supabase/supabase-js', () => ({
		createClient: mockCreateClient,
	}));

	const { getSupabaseClient } = await import('../../../services/supabaseClient');

	return {
		getSupabaseClient,
		mockCreateClient,
	};
}

afterEach(() => {
	delete process.env.SUPABASE_URL;
	delete process.env.SUPABASE_ANON_KEY;
	jest.clearAllMocks();
	jest.resetModules();
});

describe('supabaseClient service', () => {
	it('throws when SUPABASE_URL is missing', async () => {
		const { getSupabaseClient } = await loadSupabaseClientModule({
			anonKey: 'anon-key',
		});

		expect(() => getSupabaseClient()).toThrow('SUPABASE_URL and SUPABASE_ANON_KEY must be set');
	});

	it('throws when SUPABASE_ANON_KEY is missing', async () => {
		const { getSupabaseClient } = await loadSupabaseClientModule({
			url: 'https://supabase.example.co',
		});

		expect(() => getSupabaseClient()).toThrow('SUPABASE_URL and SUPABASE_ANON_KEY must be set');
	});

	it('creates and returns a supabase client with env vars', async () => {
		const { getSupabaseClient, mockCreateClient } = await loadSupabaseClientModule({
			url: 'https://supabase.example.co',
			anonKey: 'anon-key',
		});

		const client = getSupabaseClient();

		expect(client).toEqual({ id: 'supabase-client' });
		expect(mockCreateClient).toHaveBeenCalledWith('https://supabase.example.co', 'anon-key');
		expect(mockCreateClient).toHaveBeenCalledTimes(1);
	});

	it('reuses the same client instance after first initialization', async () => {
		const { getSupabaseClient, mockCreateClient } = await loadSupabaseClientModule({
			url: 'https://supabase.example.co',
			anonKey: 'anon-key',
		});

		const firstClient = getSupabaseClient();
		const secondClient = getSupabaseClient();

		expect(firstClient).toBe(secondClient);
		expect(mockCreateClient).toHaveBeenCalledTimes(1);
	});
});
