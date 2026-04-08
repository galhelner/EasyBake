import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';

type MockResponse = {
	status: ReturnType<typeof jest.fn>;
	json: ReturnType<typeof jest.fn>;
	send: ReturnType<typeof jest.fn>;
	setHeader: ReturnType<typeof jest.fn>;
};

type RecipeControllerModule = {
	createRecipe: (req: any, res: any) => Promise<void>;
	searchRecipes: (req: any, res: any) => Promise<void>;
	getRecipes: (req: any, res: any) => Promise<void>;
	getRecipeById: (req: any, res: any) => Promise<void>;
	updateRecipe: (req: any, res: any) => Promise<void>;
	deleteRecipe: (req: any, res: any) => Promise<void>;
};

type RecipeModuleLoad = {
	controller: RecipeControllerModule;
	mockAxiosPost: ReturnType<typeof jest.fn>;
	mockPrismaUserFindUnique: ReturnType<typeof jest.fn>;
	mockPrismaRecipeCreate: ReturnType<typeof jest.fn>;
	mockPrismaRecipeFindFirst: ReturnType<typeof jest.fn>;
	mockPrismaRecipeFindMany: ReturnType<typeof jest.fn>;
	mockPrismaRecipeUpdate: ReturnType<typeof jest.fn>;
	mockPrismaRecipeDelete: ReturnType<typeof jest.fn>;
	mockPrismaRecipeIngredientDeleteMany: ReturnType<typeof jest.fn>;
	mockPrismaTransaction: ReturnType<typeof jest.fn>;
	mockPrismaExecuteRaw: ReturnType<typeof jest.fn>;
	mockUploadImage: ReturnType<typeof jest.fn>;
	mockDeleteImageByPublicUrl: ReturnType<typeof jest.fn>;
	mockLoggerInfo: ReturnType<typeof jest.fn>;
	mockLoggerWarn: ReturnType<typeof jest.fn>;
};

const createMockResponse = (): MockResponse => {
	const res = {
		status: jest.fn(),
		json: jest.fn(),
		send: jest.fn(),
		setHeader: jest.fn(),
	};

	res.status.mockReturnValue(res);

	return res;
};

async function loadRecipeControllerModule(): Promise<RecipeModuleLoad> {
	jest.resetModules();

	const mockAxiosPost = jest.fn();
	const mockPrismaUserFindUnique = jest.fn();
	const mockPrismaRecipeCreate = jest.fn();
	const mockPrismaRecipeFindFirst = jest.fn();
	const mockPrismaRecipeFindMany = jest.fn();
	const mockPrismaRecipeUpdate = jest.fn();
	const mockPrismaRecipeDelete = jest.fn();
	const mockPrismaRecipeIngredientDeleteMany = jest.fn();
	const mockPrismaTransaction = jest.fn(async (operations: unknown[]) => operations);
	const mockPrismaExecuteRaw = jest.fn();
	const mockUploadImage = jest.fn();
	const mockDeleteImageByPublicUrl = jest.fn();
	const mockLoggerInfo = jest.fn();
	const mockLoggerWarn = jest.fn();

	jest.doMock('axios', () => ({
		__esModule: true,
		default: {
			post: mockAxiosPost,
		},
	}));

	jest.doMock('../../../services/prismaClient', () => ({
		__esModule: true,
		default: {
			user: {
				findUnique: mockPrismaUserFindUnique,
			},
			recipe: {
				create: mockPrismaRecipeCreate,
				findFirst: mockPrismaRecipeFindFirst,
				findMany: mockPrismaRecipeFindMany,
				update: mockPrismaRecipeUpdate,
				delete: mockPrismaRecipeDelete,
			},
			recipeIngredient: {
				deleteMany: mockPrismaRecipeIngredientDeleteMany,
			},
			$transaction: mockPrismaTransaction,
			$executeRaw: mockPrismaExecuteRaw,
		},
	}));

	jest.doMock('../../../services/storageService', () => ({
		DEFAULT_RECIPE_IMAGE_URL: 'https://example.com/default-recipe.jpg',
		uploadImage: mockUploadImage,
		deleteImageByPublicUrl: mockDeleteImageByPublicUrl,
	}));

	jest.doMock('../../../services/logger', () => ({
		__esModule: true,
		default: {
			info: mockLoggerInfo,
			warn: mockLoggerWarn,
			error: jest.fn(),
		},
	}));

	const controller = (await import('../../../controllers/recipe.controller')) as RecipeControllerModule;

	return {
		controller,
		mockAxiosPost,
		mockPrismaUserFindUnique,
		mockPrismaRecipeCreate,
		mockPrismaRecipeFindFirst,
		mockPrismaRecipeFindMany,
		mockPrismaRecipeUpdate,
		mockPrismaRecipeDelete,
		mockPrismaRecipeIngredientDeleteMany,
		mockPrismaTransaction,
		mockPrismaExecuteRaw,
		mockUploadImage,
		mockDeleteImageByPublicUrl,
		mockLoggerInfo,
		mockLoggerWarn,
	};
}

beforeEach(() => {
	jest.restoreAllMocks();
});

afterEach(() => {
	jest.clearAllMocks();
	jest.resetModules();
});

describe('recipe controller', () => {
	it('createRecipe returns 400 on validation error', async () => {
		const { controller, mockAxiosPost, mockUploadImage } = await loadRecipeControllerModule();
		const req = {
			method: 'POST',
			originalUrl: '/recipes',
			body: { title: '', instructions: [], ingredients: [] },
			user: { id: 'auth-1' },
		};
		const res = createMockResponse();

		await controller.createRecipe(req, res);

		expect(res.status).toHaveBeenCalledWith(400);
		expect(res.json).toHaveBeenCalledWith(expect.objectContaining({ error: 'Validation error' }));
		expect(mockAxiosPost).not.toHaveBeenCalled();
		expect(mockUploadImage).not.toHaveBeenCalled();
	});

	it('createRecipe returns 201 with mapped recipe on success', async () => {
		const {
			controller,
			mockAxiosPost,
			mockPrismaRecipeCreate,
			mockPrismaExecuteRaw,
			mockUploadImage,
			mockLoggerInfo,
		} = await loadRecipeControllerModule();

		mockAxiosPost
			.mockResolvedValueOnce({ data: { health_score: 82 } })
			.mockResolvedValueOnce({ data: { embedding: [1, 2, 3] } });

		mockPrismaRecipeCreate.mockResolvedValue({
			id: 'recipe-1',
			title: 'Pasta',
			instructions: ['Boil water', 'Cook pasta'],
			healthScore: 82,
			imageUrl: 'https://example.com/default-recipe.jpg',
			authorId: 'author-1',
			ingredients: [{ ingredient: { name: 'Pasta' } }],
		});

		const req = {
			method: 'POST',
			originalUrl: '/recipes',
			body: {
				title: 'Pasta',
				instructions: ['Boil water', 'Cook pasta'],
				ingredients: [{ name: 'Pasta' }],
			},
			user: { id: 'auth-1' },
			file: undefined,
		};
		const res = createMockResponse();

		await controller.createRecipe(req, res);

		expect(mockUploadImage).not.toHaveBeenCalled();
		expect(mockPrismaRecipeCreate).toHaveBeenCalledWith(
			expect.objectContaining({
				data: expect.objectContaining({
					title: 'Pasta',
					healthScore: 82,
					imageUrl: 'https://example.com/default-recipe.jpg',
				}),
			})
		);
		expect(mockPrismaExecuteRaw).toHaveBeenCalled();
		expect(mockLoggerInfo).toHaveBeenCalledWith('Incoming request: POST /recipes');
		expect(res.status).toHaveBeenCalledWith(201);
		expect(res.json).toHaveBeenCalledWith(
			expect.objectContaining({
				id: 'recipe-1',
				title: 'Pasta',
				authorId: 'author-1',
			})
		);
	});

	it('getRecipes returns 401 when unauthenticated', async () => {
		const { controller } = await loadRecipeControllerModule();
		const req = { method: 'GET', originalUrl: '/recipes', user: undefined };
		const res = createMockResponse();

		await controller.getRecipes(req, res);

		expect(res.status).toHaveBeenCalledWith(401);
		expect(res.json).toHaveBeenCalledWith({ error: 'Unauthorized' });
	});

	it('getRecipeById returns mapped recipe when found', async () => {
		const { controller, mockPrismaRecipeFindFirst } = await loadRecipeControllerModule();

		mockPrismaRecipeFindFirst.mockResolvedValue({
			id: 'recipe-1',
			title: 'Pasta',
			instructions: ['Boil water'],
			healthScore: 90,
			imageUrl: 'https://example.com/image.jpg',
			authorId: 'author-1',
			ingredients: [{ ingredient: { name: 'Pasta' } }],
		});

		const req = { method: 'GET', originalUrl: '/recipes/recipe-1', params: { id: 'recipe-1' }, user: { id: 'auth-1' } };
		const res = createMockResponse();

		await controller.getRecipeById(req, res);

		expect(res.json).toHaveBeenCalledWith(
			expect.objectContaining({
				id: 'recipe-1',
				title: 'Pasta',
				ingredients: [
					expect.objectContaining({
						name: 'Pasta',
						icon: '',
					}),
				],
			})
		);
	});

	it('updateRecipe returns 404 when recipe does not exist', async () => {
		const { controller, mockPrismaRecipeFindFirst } = await loadRecipeControllerModule();

		mockPrismaRecipeFindFirst.mockResolvedValueOnce(null);

		const req = {
			method: 'PUT',
			originalUrl: '/recipes/recipe-1',
			params: { id: 'recipe-1' },
			body: {
				title: 'Updated Pasta',
				instructions: ['Step 1'],
				ingredients: [{ name: 'Pasta' }],
			},
			user: { id: 'auth-1' },
			file: undefined,
		};
		const res = createMockResponse();

		await controller.updateRecipe(req, res);

		expect(res.status).toHaveBeenCalledWith(404);
		expect(res.json).toHaveBeenCalledWith({ error: 'Recipe not found' });
	});

	it('deleteRecipe deletes recipe and returns 204', async () => {
		const {
			controller,
			mockPrismaRecipeFindFirst,
			mockPrismaTransaction,
			mockPrismaRecipeIngredientDeleteMany,
			mockPrismaRecipeDelete,
		} = await loadRecipeControllerModule();

		mockPrismaRecipeFindFirst.mockResolvedValueOnce({ id: 'recipe-1' });

		const req = {
			method: 'DELETE',
			originalUrl: '/recipes/recipe-1',
			params: { id: 'recipe-1' },
			user: { id: 'auth-1' },
		};
		const res = createMockResponse();

		await controller.deleteRecipe(req, res);

		expect(mockPrismaRecipeIngredientDeleteMany).toHaveBeenCalledWith({
			where: { recipeId: 'recipe-1' },
		});
		expect(mockPrismaRecipeDelete).toHaveBeenCalledWith({
			where: { id: 'recipe-1' },
		});
		expect(mockPrismaTransaction).toHaveBeenCalledTimes(1);
		expect(res.status).toHaveBeenCalledWith(204);
		expect(res.send).toHaveBeenCalled();
	});
});
