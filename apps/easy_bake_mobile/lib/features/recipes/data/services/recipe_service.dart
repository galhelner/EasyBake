import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';

import '../../../../core/network/api_client.dart';
import '../../domain/models/ingredient_suggestion_model.dart';
import '../../domain/models/recipe_model.dart';

class RecipeService {
  final Dio _dio;
  static const _saveRequestTimeout = Duration(seconds: 120);

  RecipeService(this._dio);

  Future<List<RecipeModel>> fetchRecipes({CancelToken? cancelToken}) async {
    final response = await _dio.get('/recipes', cancelToken: cancelToken);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => RecipeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<RecipeModel> fetchRecipeById(String id) async {
    final response = await _dio.get('/recipes/$id');
    return RecipeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecipeModel> createRecipe(
    RecipeModel recipe, {
    bool reuseExistingHealthScore = false,
  }) async {
    final createData = recipe.toCreateJson(
      includeHealthScore: reuseExistingHealthScore,
    );
    final response = await _dio.post(
      '/recipes',
      data: createData,
      options: Options(
        sendTimeout: _saveRequestTimeout,
        receiveTimeout: _saveRequestTimeout,
      ),
    );
    return RecipeModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Creates a copy of [recipe] for the current user. If [recipe.imageUrl] is a
  /// non-default remote URL, downloads it and uploads it as multipart so the
  /// saved recipe matches the image shown in the UI (same as [createRecipeWithOptionalImage]).
  Future<RecipeModel> createRecipeCopyWithRemoteImage(
    RecipeModel recipe,
  ) async {
    final url = recipe.imageUrl?.trim();
    if (!_isNetworkRecipeImageUrl(url)) {
      return createRecipe(recipe, reuseExistingHealthScore: true);
    }

    final path = await _downloadRecipeImageToTempFile(url!);
    if (path == null) {
      return createRecipe(recipe, reuseExistingHealthScore: true);
    }

    try {
      return await createRecipeWithOptionalImage(
        recipe,
        imageFilePath: path,
        reuseExistingHealthScore: true,
      );
    } finally {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  static bool _isNetworkRecipeImageUrl(String? imageUrl) {
    final trimmed = imageUrl?.trim() ?? '';
    if (trimmed.isEmpty) {
      return false;
    }
    if (trimmed.startsWith('assets/')) {
      return false;
    }
    if (trimmed.toLowerCase().contains('default-recipe.jpg')) {
      return false;
    }
    final lower = trimmed.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  static String _imageExtensionFromDownload(
    Response<List<int>> response,
    String requestUrl,
  ) {
    final type =
        response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ?? '';
    if (type.contains('png')) {
      return 'png';
    }
    if (type.contains('webp')) {
      return 'webp';
    }
    if (type.contains('jpeg') || type.contains('jpg')) {
      return 'jpg';
    }
    if (type.contains('gif')) {
      return 'gif';
    }

    final path = Uri.tryParse(requestUrl)?.path.toLowerCase() ?? '';
    for (final ext in ['.png', '.webp', '.jpeg', '.jpg', '.gif']) {
      if (path.endsWith(ext)) {
        return ext.substring(1);
      }
    }
    return 'jpg';
  }

  Future<String?> _downloadRecipeImageToTempFile(String imageUrl) async {
    try {
      final client = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 90),
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (code) => code != null && code >= 200 && code < 300,
        ),
      );

      final response = await client.get<List<int>>(imageUrl);
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return null;
      }

      final ext = _imageExtensionFromDownload(response, imageUrl);
      final name =
          'easybake_recipe_save_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${Directory.systemTemp.path}/$name');
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<RecipeModel> updateRecipe(
    String id,
    RecipeModel recipe, {
    bool removeExistingImage = false,
  }) async {
    final updateData = recipe.toCreateJson();
    if (removeExistingImage) {
      updateData['remove_image'] = true;
    }
    final response = await _dio.put(
      '/recipes/$id',
      data: updateData,
      options: Options(
        sendTimeout: _saveRequestTimeout,
        receiveTimeout: _saveRequestTimeout,
      ),
    );
    return RecipeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecipeModel> createRecipeWithOptionalImage(
    RecipeModel recipe, {
    String? imageFilePath,
    bool reuseExistingHealthScore = false,
  }) async {
    if (imageFilePath == null || imageFilePath.isEmpty) {
      return createRecipe(
        recipe,
        reuseExistingHealthScore: reuseExistingHealthScore,
      );
    }

    final imageFile = File(imageFilePath);
    if (!await imageFile.exists()) {
      return createRecipe(
        recipe,
        reuseExistingHealthScore: reuseExistingHealthScore,
      );
    }

    final createData = recipe.toCreateJson(
      includeHealthScore: reuseExistingHealthScore,
    );
    final instructions = (createData['instructions'] as List<dynamic>?) ?? [];
    final ingredients = (createData['ingredients'] as List<dynamic>?) ?? [];
    final fileName = imageFile.path.split(RegExp(r'[\\/]')).last;

    final formData = FormData.fromMap({
      'title': createData['title'],
      // Backend preprocessors accept JSON strings in multipart fields.
      'instructions': jsonEncode(instructions),
      'ingredients': jsonEncode(ingredients),
      if (createData.containsKey('healthScore'))
        'healthScore': createData['healthScore'],
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });

    final response = await _dio.post(
      '/recipes',
      data: formData,
      options: Options(
        sendTimeout: _saveRequestTimeout,
        receiveTimeout: _saveRequestTimeout,
      ),
    );
    return RecipeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecipeModel> createRecipeFromImage(String imageFilePath) async {
    final imageFile = File(imageFilePath);
    if (!await imageFile.exists()) {
      throw Exception('Image file not found');
    }

    final fileName = imageFile.path.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });

    final response = await _dio.post(
      '/recipes/create-from-image',
      data: formData,
      options: Options(
        sendTimeout: _saveRequestTimeout,
        receiveTimeout: _saveRequestTimeout,
      ),
    );

    return RecipeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RecipeModel> updateRecipeWithOptionalImage(
    String id,
    RecipeModel recipe, {
    String? imageFilePath,
    bool removeExistingImage = false,
  }) async {
    if (imageFilePath == null || imageFilePath.isEmpty) {
      return updateRecipe(id, recipe, removeExistingImage: removeExistingImage);
    }

    final imageFile = File(imageFilePath);
    if (!await imageFile.exists()) {
      return updateRecipe(id, recipe, removeExistingImage: removeExistingImage);
    }

    final updateData = recipe.toCreateJson();
    final instructions = (updateData['instructions'] as List<dynamic>?) ?? [];
    final ingredients = (updateData['ingredients'] as List<dynamic>?) ?? [];
    final fileName = imageFile.path.split(RegExp(r'[\\/]')).last;

    final formData = FormData.fromMap({
      'title': updateData['title'],
      // Backend preprocessors accept JSON strings in multipart fields.
      'instructions': jsonEncode(instructions),
      'ingredients': jsonEncode(ingredients),
      if (removeExistingImage) 'remove_image': 'true',
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });

    final response = await _dio.put(
      '/recipes/$id',
      data: formData,
      options: Options(
        sendTimeout: _saveRequestTimeout,
        receiveTimeout: _saveRequestTimeout,
      ),
    );
    return RecipeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRecipe(String id) async {
    await _dio.delete('/recipes/$id');
  }

  Future<List<IngredientSuggestionModel>> fetchIngredientSuggestions(
    String query,
  ) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final response = await _dio.get(
      '/recipes/ingredients/search',
      queryParameters: {'q': trimmed},
    );

    final data = response.data as List<dynamic>;
    return data
        .map(
          (item) =>
              IngredientSuggestionModel.fromJson(item as Map<String, dynamic>),
        )
        .where((item) => item.name.isNotEmpty)
        .toList();
  }
}

final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService(ref.read(dioProvider));
});
