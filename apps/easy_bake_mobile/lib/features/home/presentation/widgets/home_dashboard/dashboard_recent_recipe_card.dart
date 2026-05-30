import 'package:flutter/material.dart';

import '../../../../recipes/domain/models/recipe_model.dart';
import '../../../../recipes/presentation/widgets/recipe_list/recipe_card.dart';
import 'dashboard_types.dart';

class DashboardRecentRecipeCard extends StatelessWidget {
  const DashboardRecentRecipeCard({super.key, required this.recipe});

  final RecipeModel recipe;

  @override
  Widget build(BuildContext context) {
    return RecipeCard(
      recipe: recipe,
      imageUrl: recipe.imageUrl,
      statusColor: dashboardStatusColor(recipe.healthScore),
      variant: RecipeCardVariant.dashboard,
    );
  }
}
