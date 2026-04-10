import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/services/recipe_service.dart';
import '../../domain/models/recipe_model.dart';

final recipesListProvider = FutureProvider.autoDispose<List<RecipeModel>>((
  ref,
) async {
  // Check if user is authenticated before attempting to fetch
  final authState = ref.watch(authNotifierProvider);

  if (!authState.isAuthenticated || authState.accessToken == null) {
    throw Exception('Not authenticated - token is invalid or expired');
  }

  final service = ref.read(recipeServiceProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  try {
    return await service
        .fetchRecipes(cancelToken: cancelToken)
      .timeout(const Duration(seconds: 45));
  } on TimeoutException {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Timed out while loading recipes');
    }
    throw Exception(
      'Server is not responding. Please check if recipe-service is running and try again.',
    );
  } on DioException catch (error) {
    if (CancelToken.isCancel(error)) {
      throw Exception('Request cancelled');
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      throw Exception(
        'Cannot reach the server. Please start recipe-service and refresh.',
      );
    }    // Convert HTTP status errors to user-friendly messages
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      throw Exception('Your session has expired. Please sign in again.');
    }
    if (statusCode == 404) {
      throw Exception('Recipes not found.');
    }
    if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
      throw Exception('Server error. Please try again later.');
    }
    if (statusCode != null) {
      throw Exception(
        'An error occurred while loading recipes. Please try again.',
      );
    }    rethrow;
  }
});
