import 'package:flutter/material.dart';

import 'skeleton_recipe_card.dart';

class RecipeListSkeletonSliver extends StatelessWidget {
  const RecipeListSkeletonSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          return const SkeletonRecipeCard();
        },
      ),
    );
  }
}
