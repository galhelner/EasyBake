import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../../recipes/domain/models/recipe_model.dart';
import 'dashboard_empty_dashboard_card.dart';
import 'dashboard_recent_recipe_card.dart';
import 'dashboard_recipes_loading_state.dart';

class DashboardMyRecipesSection extends StatelessWidget {
  const DashboardMyRecipesSection({
    super.key,
    required this.l10n,
    required this.recipes,
    required this.isLoading,
    required this.onSeeAllRecipes,
  });

  final AppLocalizations l10n;
  final List<RecipeModel> recipes;
  final bool isLoading;
  final VoidCallback onSeeAllRecipes;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const DashboardRecipesLoadingState();
    }

    if (recipes.isEmpty) {
      return DashboardEmptyCard(
        icon: Icons.menu_book_rounded,
        title: l10n.noRecipesYetTitle,
        subtitle: l10n.dashboardNoRecipesSubtitle,
        actionLabel: l10n.seeAllLabel,
        onActionTap: onSeeAllRecipes,
      );
    }

    return SizedBox(
      height: 198,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 4),
        itemCount: recipes.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 166,
          child: DashboardRecentRecipeCard(recipe: recipes[index]),
        ),
      ),
    );
  }
}