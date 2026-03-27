import 'package:flutter/material.dart';

import '../../domain/models/recipe_model.dart';

class RecipeDetailsDialog extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeDetailsDialog({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(recipe.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.ingredients.isNotEmpty) ...[
              const Text('Ingredients:'),
              const SizedBox(height: 4),
              ...recipe.ingredients.map((i) => Text('- $i')),
              const SizedBox(height: 12),
            ],
            if (recipe.instructions.isNotEmpty) ...[
              const Text('Instructions:'),
              const SizedBox(height: 4),
              ...recipe.instructions.map((line) => Text('- $line')),
              const SizedBox(height: 12),
            ],
            Text('Health score: ${recipe.healthScore}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
