import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/recipe_service.dart';
import '../../domain/models/recipe_model.dart';

final recipesListProvider = FutureProvider.autoDispose<List<RecipeModel>>((
  ref,
) async {
  final service = ref.read(recipeServiceProvider);
  return service.fetchRecipes();
});
