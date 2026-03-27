import 'package:flutter/material.dart';

import 'skeleton_recipe_card.dart';

class RecipeListSkeletonSliver extends StatelessWidget {
  const RecipeListSkeletonSliver({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        itemCount: 5,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 143 / 174,
        ),
        itemBuilder: (context, index) {
          return const SkeletonRecipeCard();
        },
      ),
    );
  }
}
