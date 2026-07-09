import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../domain/models/recipe_model.dart';
import '../../../domain/models/folder_model.dart';
import '../../providers/recipe_providers.dart';
import 'recipe_card.dart';
import 'recipe_simple_list.dart';
import 'folder_card.dart';

class RecipeListContent extends ConsumerWidget {
  final List<RecipeModel> recipes;
  final String query;

  const RecipeListContent({
    super.key,
    required this.recipes,
    required this.query,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final viewMode = ref.watch(recipeViewModeProvider);
    final isListMode = viewMode == 'list';
    final currentFolderId = ref.watch(currentFolderIdProvider);
    final foldersAsync = ref.watch(foldersListProvider);
    final foldersExpanded = ref.watch(foldersExpandedProvider);
    final recipesExpanded = ref.watch(recipesExpandedProvider);

    // Filter recipes: if searching, search globally; otherwise, filter by currentFolderId
    final filteredRecipes = query.isEmpty
        ? recipes.where((recipe) => recipe.folderId == currentFolderId).toList()
        : recipes
            .where(
              (recipe) =>
                  recipe.title.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    // Filter folders: only when not searching
    final filteredFolders = query.isEmpty
        ? foldersAsync.maybeWhen(
            data: (folders) =>
                folders.where((folder) => folder.parentId == currentFolderId).toList(),
            orElse: () => <FolderModel>[],
          )
        : <FolderModel>[];

    if (filteredRecipes.isEmpty && filteredFolders.isEmpty) {
      final isSearching = query.trim().isNotEmpty;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _RecipesEmptyState(
          isSearching: isSearching,
          isInsideFolder: currentFolderId != null,
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        if (filteredFolders.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: l10n.foldersHeaderLabel,
              icon: Icons.folder_open_rounded,
              isExpanded: foldersExpanded,
              onToggle: () => ref.read(foldersExpandedProvider.notifier).state = !foldersExpanded,
            ),
          ),
          if (foldersExpanded)
            isListMode
                ? SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: filteredFolders.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FolderCard(
                            folder: filteredFolders[index],
                            isListMode: true,
                          ),
                        );
                      },
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid.builder(
                      itemCount: filteredFolders.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                      ),
                      itemBuilder: (context, index) {
                        return FolderCard(
                          folder: filteredFolders[index],
                          isListMode: false,
                        );
                      },
                    ),
                  ),
        ],
        if (filteredFolders.isNotEmpty && filteredRecipes.isNotEmpty)
          SliverToBoxAdapter(
            child: _SectionHeader(
              title: l10n.recipesHeaderLabel,
              icon: Icons.restaurant_menu_rounded,
              isExpanded: recipesExpanded,
              onToggle: () => ref.read(recipesExpandedProvider.notifier).state = !recipesExpanded,
            ),
          ),
        if (filteredRecipes.isNotEmpty && recipesExpanded)
          isListMode
              ? RecipeSimpleListView(recipes: filteredRecipes)
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid.builder(
                    itemCount: filteredRecipes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, index) {
                      final recipe = filteredRecipes[index];
                      return RecipeCard(
                        recipe: recipe,
                        imageUrl: recipe.imageUrl,
                        statusColor: _statusColor(recipe.healthScore),
                      );
                    },
                  ),
                ),
      ],
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
  const _RecipesEmptyState({
    required this.isSearching,
    this.isInsideFolder = false,
  });

  final bool isSearching;
  final bool isInsideFolder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = isSearching
        ? l10n.noRecipesFoundTitle
        : (isInsideFolder ? l10n.emptyFolderTitle : l10n.noRecipesYetTitle);
    final subtitle = isSearching
        ? l10n.noRecipesFoundSubtitle
        : (isInsideFolder ? l10n.emptyFolderSubtitle : l10n.noRecipesYetSubtitle);
    final bottomSafeSpace = isSearching ? 120.0 : 20.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 40, 24, bottomSafeSpace),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E8ED), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E4E69).withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE0E8ED),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isSearching
                          ? Icons.search_off_rounded
                          : (isInsideFolder ? Icons.folder_open_rounded : Icons.menu_book_rounded),
                      size: 40,
                      color: const Color(0xFF8BB3D6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF20364B),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF4E677D).withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF8BB3D6),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F3559),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Divider(
                color: Color(0xFFDCE7F1),
                thickness: 1.5,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Color(0xFF8BB3D6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

