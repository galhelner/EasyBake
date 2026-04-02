import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';

type StorageModuleResult = {
	uploadImage: (file: Express.Multer.File) => Promise<string>;
	mockCreateClient: ReturnType<typeof jest.fn>;
	mockUpload: ReturnType<typeof jest.fn>;
	mockGetPublicUrl: ReturnType<typeof jest.fn>;
	mockReadFile: ReturnType<typeof jest.fn>;
};

const defaultEnv = {
	SUPABASE_URL: 'https://supabase.example.co',
	SUPABASE_SERVICE_ROLE_KEY: 'service-role-key',
};

async function loadStorageModule(options?: {
	uploadErrorMessage?: string;
	publicUrl?: string;
	readFileBuffer?: Buffer;
}): Promise<StorageModuleResult> {
	jest.resetModules();

	process.env.SUPABASE_URL = defaultEnv.SUPABASE_URL;
	process.env.SUPABASE_SERVICE_ROLE_KEY = defaultEnv.SUPABASE_SERVICE_ROLE_KEY;
	delete process.env.SUPABASE_ANON_KEY;

	const mockUpload = jest.fn(async () => ({
		error: options?.uploadErrorMessage ? { message: options.uploadErrorMessage } : null,
	}));
	const mockGetPublicUrl = jest.fn(() => ({
		data: {
			publicUrl:
				options?.publicUrl ?? 'https://supabase.example.co/storage/v1/object/public/recipe-images/recipes/image.jpg',
		},
	}));
	const mockFrom = jest.fn(() => ({
		upload: mockUpload,
		getPublicUrl: mockGetPublicUrl,
	}));
	const mockCreateClient = jest.fn(() => ({
		storage: {
			from: mockFrom,
		},
	}));
	const mockReadFile = jest.fn(async () => options?.readFileBuffer ?? Buffer.from('from-path'));

	jest.doMock('@supabase/supabase-js', () => ({
		createClient: mockCreateClient,
	}));

	jest.doMock('fs/promises', () => ({
		readFile: mockReadFile,
	}));

	jest.doMock('crypto', () => ({
		randomUUID: jest.fn(() => 'fixed-uuid'),
	}));

	jest.spyOn(Date, 'now').mockReturnValue(1712000000000);

	const { uploadImage } = await import('../../../services/storageService');

	return {
		uploadImage,
		mockCreateClient,
		mockUpload,
		mockGetPublicUrl,
		mockReadFile,
	};
}

beforeEach(() => {
	jest.restoreAllMocks();
});

afterEach(() => {
	delete process.env.SUPABASE_URL;
	delete process.env.SUPABASE_SERVICE_ROLE_KEY;
	delete process.env.SUPABASE_ANON_KEY;
	jest.clearAllMocks();
	jest.resetModules();
});

describe('storageService uploadImage', () => {
	it('throws when no file is provided', async () => {
		const { uploadImage } = await loadStorageModule();

		await expect(uploadImage(undefined as unknown as Express.Multer.File)).rejects.toThrow(
			'No file provided'
		);
	});

	it('throws when file is not an image', async () => {
		const { uploadImage } = await loadStorageModule();

		await expect(
			uploadImage({ mimetype: 'application/pdf' } as Express.Multer.File)
		).rejects.toThrow('Only image files are supported');
	});

	it('uploads image bytes from buffer and returns public URL', async () => {
		const { uploadImage, mockCreateClient, mockUpload, mockGetPublicUrl, mockReadFile } =
			await loadStorageModule();
		const fileBuffer = Buffer.from('image-buffer');

		const publicUrl = await uploadImage({
			mimetype: 'image/png',
			originalname: 'pizza.PNG',
			buffer: fileBuffer,
		} as Express.Multer.File);

		expect(publicUrl).toContain('recipe-images');
		expect(mockCreateClient).toHaveBeenCalledWith(
			defaultEnv.SUPABASE_URL,
			defaultEnv.SUPABASE_SERVICE_ROLE_KEY
		);
		expect(mockUpload).toHaveBeenCalledWith(
			'recipes/1712000000000-fixed-uuid.png',
			fileBuffer,
			{
				contentType: 'image/png',
				upsert: false,
			}
		);
		expect(mockGetPublicUrl).toHaveBeenCalledWith('recipes/1712000000000-fixed-uuid.png');
		expect(mockReadFile).not.toHaveBeenCalled();
	});

	it('reads file from path when buffer is empty', async () => {
		const fileFromPath = Buffer.from('file-from-path');
		const { uploadImage, mockReadFile, mockUpload } = await loadStorageModule({
			readFileBuffer: fileFromPath,
		});

		await uploadImage({
			mimetype: 'image/jpeg',
			originalname: 'photo.jpg',
			path: '/tmp/photo.jpg',
			buffer: Buffer.alloc(0),
		} as Express.Multer.File);

		expect(mockReadFile).toHaveBeenCalledWith('/tmp/photo.jpg');
		expect(mockUpload).toHaveBeenCalledWith(
			'recipes/1712000000000-fixed-uuid.jpg',
			fileFromPath,
			expect.any(Object)
		);
	});

	it('throws when supabase upload fails', async () => {
		const { uploadImage } = await loadStorageModule({
			uploadErrorMessage: 'permission denied',
		});

		await expect(
			uploadImage({
				mimetype: 'image/webp',
				originalname: 'dish.webp',
				buffer: Buffer.from('bytes'),
			} as Express.Multer.File)
		).rejects.toThrow('Image upload failed: permission denied');
	});

	it('throws when required supabase env vars are missing', async () => {
		jest.resetModules();
		delete process.env.SUPABASE_URL;
		delete process.env.SUPABASE_SERVICE_ROLE_KEY;
		delete process.env.SUPABASE_ANON_KEY;

		const mockUpload = jest.fn();
		const mockGetPublicUrl = jest.fn();

		jest.doMock('@supabase/supabase-js', () => ({
			createClient: jest.fn(() => ({
				storage: {
					from: jest.fn(() => ({
						upload: mockUpload,
						getPublicUrl: mockGetPublicUrl,
					})),
				},
			})),
		}));

		jest.doMock('fs/promises', () => ({
			readFile: jest.fn(async () => Buffer.from('ignored')),
		}));

		jest.doMock('crypto', () => ({
			randomUUID: jest.fn(() => 'fixed-uuid'),
		}));

		const { uploadImage } = await import('../../../services/storageService');

		await expect(
			uploadImage({
				mimetype: 'image/png',
				originalname: 'dish.png',
				buffer: Buffer.from('bytes'),
			} as Express.Multer.File)
		).rejects.toThrow('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY (or SUPABASE_ANON_KEY) must be set');
	});
});
