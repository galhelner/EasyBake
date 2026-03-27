import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/models/recipe_model.dart';

class RecipeService {
  final Dio _dio;

  RecipeService(this._dio);

  Future<List<RecipeModel>> fetchRecipes() async {
    final response = await _dio.get('/recipes');
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
    final response = await _dio.post('/recipes', data: recipe.toCreateJson());
    return RecipeModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService(ref.read(dioProvider));
});
