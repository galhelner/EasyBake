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
  return service.fetchRecipes();
});
