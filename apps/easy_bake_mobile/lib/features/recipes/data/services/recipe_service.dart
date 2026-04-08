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

  Future<RecipeModel> createRecipe(RecipeModel recipe) async {
    final createData = recipe.toCreateJson();
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

  Future<RecipeModel> updateRecipe(String id, RecipeModel recipe) async {
    final updateData = recipe.toCreateJson();
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
  }) async {
    if (imageFilePath == null || imageFilePath.isEmpty) {
      return createRecipe(recipe);
    }

    final imageFile = File(imageFilePath);
    if (!await imageFile.exists()) {
      return createRecipe(recipe);
    }

    final createData = recipe.toCreateJson();
    final instructions = (createData['instructions'] as List<dynamic>?) ?? [];
    final ingredients = (createData['ingredients'] as List<dynamic>?) ?? [];
    final fileName = imageFile.path.split(RegExp(r'[\\/]')).last;

    final formData = FormData.fromMap({
      'title': createData['title'],
      // Backend preprocessors accept JSON strings in multipart fields.
      'instructions': jsonEncode(instructions),
      'ingredients': jsonEncode(ingredients),
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });

    final response = await _dio.post(
      '/recipes',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
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
  }) async {
    if (imageFilePath == null || imageFilePath.isEmpty) {
      return updateRecipe(id, recipe);
    }

    final imageFile = File(imageFilePath);
    if (!await imageFile.exists()) {
      return updateRecipe(id, recipe);
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
      'image': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });

    final response = await _dio.put(
      '/recipes/$id',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
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
