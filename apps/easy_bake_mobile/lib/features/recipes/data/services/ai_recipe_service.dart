import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/models/recipe_model.dart';

const _aiServiceBaseUrlAndroid = 'http://10.0.2.2:8000/api';
const _aiServiceBaseUrlDesktop = 'http://localhost:8000/api';

class AiRecipeService {
  final Dio _dio;

  AiRecipeService({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: _baseUrl));

  static String get _baseUrl =>
      Platform.isAndroid ? _aiServiceBaseUrlAndroid : _aiServiceBaseUrlDesktop;

  Future<RecipeModel> generateRecipe(String prompt) async {
    final response = await _dio.post('/parse-recipe', data: {'prompt': prompt});
    final data = response.data as Map<String, dynamic>;

    final ingredients =
        (data['ingredients'] as List<dynamic>?)
            ?.map((item) => (item as Map<String, dynamic>)['name'] as String)
            .toList() ??
        [];

    final instructions =
        (data['instructions'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    return RecipeModel(
      title: data['title'] as String? ?? 'Untitled',
      ingredients: ingredients,
      instructions: instructions,
      healthScore: (data['health_score'] as int?) ?? 5,
    );
  }
}
