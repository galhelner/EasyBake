import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/recipe_model.dart';
import '../../providers/recipe_providers.dart';
import '../../pages/recipe_details_page.dart';

class RecipeDraggableListView extends ConsumerStatefulWidget {
  final List<RecipeModel> recipes;
  final String query;

  const RecipeDraggableListView({
    super.key,
    required this.recipes,
    required this.query,
  });

  @override
  ConsumerState<RecipeDraggableListView> createState() =>
      _RecipeDraggableListViewState();
}

class _RecipeDraggableListViewState
    extends ConsumerState<RecipeDraggableListView> {
  late List<RecipeModel> _reorderableRecipes;

  @override
  void initState() {
    super.initState();
    // Initialize with recipes, preserving any previous order
    final savedOrder = ref.read(recipeListOrderProvider);
    if (savedOrder.isNotEmpty) {
      // Sort recipes according to saved order
      _reorderableRecipes = _sortBySavedOrder(widget.recipes, savedOrder);
    } else {
      _reorderableRecipes = List.from(widget.recipes);
    }
  }

  @override
  void didUpdateWidget(RecipeDraggableListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recipes != widget.recipes) {
      final savedOrder = ref.read(recipeListOrderProvider);
      if (savedOrder.isNotEmpty) {
        _reorderableRecipes = _sortBySavedOrder(widget.recipes, savedOrder);
      } else {
        _reorderableRecipes = List.from(widget.recipes);
      }
    }
  }

  List<RecipeModel> _sortBySavedOrder(
    List<RecipeModel> recipes,
    List<String> savedOrder,
  ) {
    final sorted = <RecipeModel>[];
    for (final id in savedOrder) {
      try {
        final recipe = recipes.firstWhere((r) => r.id == id);
        sorted.add(recipe);
      } catch (_) {
        // Recipe not found, skip
      }
    }
    // Add any recipes that weren't in the saved order (new recipes)
    for (final recipe in recipes) {
      if (!sorted.contains(recipe)) {
        sorted.add(recipe);
      }
    }
    return sorted;
  }

  List<RecipeModel> get _filteredRecipes {
    if (widget.query.isEmpty) {
      return _reorderableRecipes;
    }

    return _reorderableRecipes
        .where(
          (recipe) =>
              recipe.title.toLowerCase().contains(widget.query.toLowerCase()),
        )
        .toList();
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _reorderableRecipes.removeAt(oldIndex);
      _reorderableRecipes.insert(newIndex, item);
    });
    // Save the new order to the provider
    _updateOrderProvider();
  }

  void _updateOrderProvider() {
    final order = _reorderableRecipes
        .map((recipe) => recipe.id)
        .whereType<String>()
        .toList();
    ref.read(recipeListOrderProvider.notifier).updateOrder(order);
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = _filteredRecipes;

    if (filteredRecipes.isEmpty) {
      final isSearching = widget.query.trim().isNotEmpty;
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _RecipesEmptyState(isSearching: isSearching),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverReorderableList(
        onReorder: _onReorder,
        itemCount: filteredRecipes.length,
        itemBuilder: (context, index) {
          final recipe = filteredRecipes[index];
          return ReorderableDelayedDragStartListener(
            key: ValueKey(recipe.id),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DraggableRecipeItem(
                recipe: recipe,
                index: index,
                statusColor: _statusColor(recipe.healthScore),
              ),
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

class _DraggableRecipeItem extends StatelessWidget {
  final RecipeModel recipe;
  final int index;
  final Color statusColor;

  const _DraggableRecipeItem({
    required this.recipe,
    required this.index,
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
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.drag_handle_rounded,
                    color: const Color(0xFF8BB3D6),
                    size: 24,
                  ),
                ),
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

class _RecipesEmptyState extends StatelessWidget {
  const _RecipesEmptyState({required this.isSearching});

  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final title = isSearching
        ? 'No recipes found'
        : 'Your recipe collection is empty';
    final subtitle = isSearching
        ? 'Use AI Chef chat to semantically search your recipes.'
        : 'Tap the + button to add your first recipe, or use AI to create one for you.';
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
                // Icon Container
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
                          : Icons.menu_book_rounded,
                      size: 40,
                      color: const Color(0xFF8BB3D6),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
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
                // Subtitle
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF4E677D).withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
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
