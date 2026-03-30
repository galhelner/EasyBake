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
      final isSearching = query.trim().isNotEmpty;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _RecipesEmptyState(isSearching: isSearching),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        itemCount: recipes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
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

class _RecipesEmptyState extends StatelessWidget {
  const _RecipesEmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final title = isSearching ? 'No recipes found' : 'Your recipe collection is empty';
    final subtitle = isSearching
        ? 'Try searching with different keywords or clear your search to see all recipes.'
        : 'Tap the + button to add your first recipe, or use AI to create one for you.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFE0E8ED),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E4E69).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Container
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE0E8ED),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isSearching
                          ? Icons.search_off_rounded
                          : Icons.menu_book_rounded,
                      size: 40,
                      color: const Color(0xFF8BB3D6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF20364B),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF4E677D).withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
