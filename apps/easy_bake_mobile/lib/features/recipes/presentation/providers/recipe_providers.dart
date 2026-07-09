import 'dart:async';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/services/recipe_service.dart';
import '../../domain/models/recipe_model.dart';
import '../../domain/models/folder_model.dart';

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
    } // Convert HTTP status errors to user-friendly messages
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      // Clear auth state to trigger redirect to login
      // Use addPostFrameCallback to avoid ticker conflicts during navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authNotifierProvider.notifier).clear();
      });
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
    }
    rethrow;
  }
});

/// View mode for the recipe list: 'grid' or 'list'
final recipeViewModeProvider = NotifierProvider<RecipeViewModeNotifier, String>(
  RecipeViewModeNotifier.new,
);

class RecipeViewModeNotifier extends Notifier<String> {
  @override
  String build() => 'grid'; // Default to grid view

  void toggle() {
    state = state == 'grid' ? 'list' : 'grid';
  }

  void setMode(String mode) {
    state = mode;
  }
}

final foldersListProvider = FutureProvider.autoDispose<List<FolderModel>>((ref) async {
  final authState = ref.watch(authNotifierProvider);

  if (!authState.isAuthenticated || authState.accessToken == null) {
    throw Exception('Not authenticated - token is invalid or expired');
  }

  final service = ref.read(recipeServiceProvider);
  final cancelToken = CancelToken();
  ref.onDispose(cancelToken.cancel);

  try {
    return await service
        .fetchFolders(cancelToken: cancelToken)
        .timeout(const Duration(seconds: 45));
  } on TimeoutException {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Timed out while loading folders');
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
    }
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authNotifierProvider.notifier).clear();
      });
      throw Exception('Your session has expired. Please sign in again.');
    }
    if (statusCode == 404) {
      throw Exception('Folders not found.');
    }
    if (statusCode == 500 || statusCode == 502 || statusCode == 503) {
      throw Exception('Server error. Please try again later.');
    }
    if (statusCode != null) {
      throw Exception(
        'An error occurred while loading folders. Please try again.',
      );
    }
    rethrow;
  }
});

class CurrentFolderIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  @override
  set state(String? val) => super.state = val;
}

final currentFolderIdProvider = NotifierProvider<CurrentFolderIdNotifier, String?>(CurrentFolderIdNotifier.new);

class FoldersExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  @override
  set state(bool val) => super.state = val;
}

final foldersExpandedProvider = NotifierProvider<FoldersExpandedNotifier, bool>(FoldersExpandedNotifier.new);

class RecipesExpandedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  @override
  set state(bool val) => super.state = val;
}

final recipesExpandedProvider = NotifierProvider<RecipesExpandedNotifier, bool>(RecipesExpandedNotifier.new);



