import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../recipes/domain/models/recipe_model.dart';
import '../../../recipes/presentation/providers/recipe_providers.dart';
import '../../../recipes/presentation/widgets/ai_chef_chat_button.dart';
import '../../../shopping-list/presentation/providers/shopping_list_providers.dart';
import '../widgets/home_dashboard/dashboard_backdrop.dart';
import '../widgets/home_dashboard/dashboard_health_statistics_section.dart';
import '../widgets/home_dashboard/dashboard_hero_card.dart';
import '../widgets/home_dashboard/dashboard_my_recipes_section.dart';
import '../widgets/home_dashboard/dashboard_section_card.dart';
import '../widgets/home_dashboard/dashboard_shopping_list_section.dart';

class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({
    super.key,
    required this.onSeeAllRecipes,
    required this.onSeeAllShoppingList,
    required this.onOpenAiChefChat,
  });

  final VoidCallback onSeeAllRecipes;
  final VoidCallback onSeeAllShoppingList;
  final VoidCallback onOpenAiChefChat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recipesAsync = ref.watch(recipesListProvider);
    final recipes = recipesAsync.asData?.value ?? const <RecipeModel>[];
    final isLoading = recipesAsync.isLoading && recipes.isEmpty;
    final shoppingListAsync = ref.watch(shoppingListItemsProvider);

    final authState = ref.watch(authNotifierProvider);
    final fullName = authState.fullName?.trim();
    final displayName = fullName != null && fullName.isNotEmpty
        ? fullName
        : l10n.easyBakeUserFallback;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FB),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: AiChefChatButton(onTap: onOpenAiChefChat),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const DashboardBackdrop(),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 124),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DashboardHeroCard(displayName: displayName),
                  const SizedBox(height: 16),
                  DashboardSectionCard(
                    title: l10n.myRecipesLabel,
                    actionLabel: l10n.seeAllLabel,
                    onActionTap: onSeeAllRecipes,
                    contentTopSpacing: 12,
                    child: DashboardMyRecipesSection(
                      l10n: l10n,
                      recipes: recipes.take(4).toList(),
                      isLoading: isLoading,
                      onSeeAllRecipes: onSeeAllRecipes,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DashboardSectionCard(
                    title: l10n.healthStatisticsLabel,
                    child: DashboardHealthStatisticsSection(
                      l10n: l10n,
                      recipes: recipes,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DashboardSectionCard(
                    title: l10n.shoppingListPageTitle,
                    actionLabel: l10n.seeAllLabel,
                    onActionTap: onSeeAllShoppingList,
                    contentTopSpacing: 8,
                    child: shoppingListAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF17324B)),
                            ),
                          ),
                        ),
                      ),
                      error: (err, stack) => Text(
                        l10n.shoppingListLoadFailedMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                      data: (items) {
                        if (items.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.shoppingListEmptyTitle,
                              style: const TextStyle(
                                color: Color(0xFF6E8298),
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        }

                        return DashboardShoppingListSection(
                          items: items.take(5).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
