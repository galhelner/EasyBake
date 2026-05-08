import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../recipes/domain/models/recipe_model.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.recipesAsync});

  final AsyncValue<List<RecipeModel>> recipesAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E4EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF2E4E69),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: recipesAsync.when(
              data: (recipes) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${recipes.length} saved recipes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F334A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Your personal recipe collection',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5D7489)),
                  ),
                ],
              ),
              loading: () => const Text(
                'Loading your recipe summary...',
                style: TextStyle(fontSize: 14, color: Color(0xFF5D7489)),
              ),
              error: (_, stackTrace) => const Text(
                'Recipe summary unavailable right now',
                style: TextStyle(fontSize: 14, color: Color(0xFF5D7489)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
