import 'package:flutter/material.dart';

import 'recipe_search_result_card.dart';

/// Displays a list of recipe search results
class AiChefSearchResults extends StatelessWidget {
  const AiChefSearchResults({
    this.message = '',
    required this.recipes,
    required this.onRecipeTap,
    super.key,
  });

  final String message;
  final List<dynamic> recipes;
  final Function(Map<String, dynamic>) onRecipeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
                height: 1.35,
              ),
            ),
          ),
        if (recipes.isNotEmpty)
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE5EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...recipes.asMap().entries.map((entry) {
                  final recipe = entry.value as Map<String, dynamic>;
                  final title = recipe['title']?.toString() ?? 'Untitled Recipe';
                  final healthScore =
                      (recipe['healthScore'] as num?)?.toInt() ?? 50;
                  final imageUrl = recipe['imageUrl']?.toString() ?? '';

                  return RecipeSearchResultCard(
                    title: title,
                    healthScore: healthScore,
                    imageUrl: imageUrl,
                    recipe: recipe,
                    showBottomDivider: entry.key != recipes.length - 1,
                    onTap: () => onRecipeTap(recipe),
                  );
                }),
              ],
            ),
          )
        else
          const Text(
            'No recipes found.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              height: 1.35,
            ),
          ),
      ],
    );
  }
}
