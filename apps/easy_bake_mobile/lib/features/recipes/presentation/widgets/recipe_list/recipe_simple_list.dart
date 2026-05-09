import 'package:flutter/material.dart';

import '../../../domain/models/recipe_model.dart';
import '../../pages/recipe_details_page.dart';

class RecipeSimpleListView extends StatelessWidget {
  final List<RecipeModel> recipes;

  const RecipeSimpleListView({
    super.key,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecipeListItem(
              recipe: recipe,
              statusColor: _statusColor(recipe.healthScore),
            ),
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

class _RecipeListItem extends StatelessWidget {
  final RecipeModel recipe;
  final Color statusColor;

  const _RecipeListItem({
    required this.recipe,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailsPage(initialRecipe: recipe),
          ),
        );
      },
      child: Material(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E4E69).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: const Color(0xFF2E4E69).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Recipe image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                        ? Image.network(
                            recipe.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.restaurant_rounded,
                                color: const Color(
                                  0xFF8BB3D6,
                                ).withValues(alpha: 0.5),
                                size: 40,
                              );
                            },
                          )
                        : Icon(
                            Icons.restaurant_rounded,
                            color: const Color(
                              0xFF8BB3D6,
                            ).withValues(alpha: 0.5),
                            size: 40,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Recipe info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        recipe.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF20364B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${recipe.healthScore}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
