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

class _RecipesEmptyState extends StatelessWidget {
  const _RecipesEmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final title = isSearching ? 'No matching recipes' : 'Your recipe book is empty';
    final subtitle = isSearching
        ? 'Try a different keyword or clear search to see all recipes.'
        : 'Tap the + button below to add your first recipe, or ask AI to create one for you.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 20),
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8FBFD), Color(0xFFEAF2F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD2E2EE)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F1A2A3A),
                blurRadius: 16,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFCBDCE8)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      isSearching ? Icons.search_off_rounded : Icons.menu_book_rounded,
                      size: 34,
                      color: const Color(0xFF2E4E69),
                    ),
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFC857),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF20364B),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4E677D),
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
