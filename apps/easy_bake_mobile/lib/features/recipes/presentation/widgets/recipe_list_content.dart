import 'package:flutter/material.dart';

import '../../domain/models/recipe_model.dart';
import 'recipe_card.dart';

class RecipeListContent extends StatelessWidget {
  final List<RecipeModel> recipes;
  final String query;

  const RecipeListContent({
    super.key,
    required this.recipes,
    required this.query,
  });

  List<RecipeModel> get _filteredRecipes {
    if (query.isEmpty) {
      return recipes;
    }

    return recipes
        .where(
          (recipe) => recipe.title.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _filteredRecipes;

    if (recipes.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No recipes match your search.')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        itemCount: recipes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 143 / 174,
        ),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return RecipeCard(
            recipe: recipe,
            imageUrl: recipe.imageUrl,
            statusColor: _statusColor(recipe.healthScore),
          );
        },
      ),
    );
  }

  Color _statusColor(int healthScore) {
    if (healthScore >= 70) {
      return const Color(0xFF34C759);
    }
    if (healthScore >= 40) {
      return const Color(0xFFF5B52E);
    }
    return const Color(0xFFFF3B30);
  }
}
