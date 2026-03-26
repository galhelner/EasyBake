import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import '../auth/login_page.dart';
import '../../core/widgets/skeleton.dart';
import 'recipe_create_page.dart';
import 'domain/recipe_model.dart';
import 'recipe_service.dart';

class RecipeListPage extends ConsumerWidget {
  const RecipeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F7),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: RefreshIndicator(
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          onRefresh: () async {
            ref.invalidate(recipesListProvider);
            await ref.read(recipesListProvider.future);
          },
          child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Static Header - Always Visible
            SliverToBoxAdapter(
              child: _RecipeListHeader(),
            ),
            // Recipe Content - AsyncValue with Loading Skeleton
            recipesAsync.when(
              data: (recipes) => _RecipeListContent(recipes: recipes),
              loading: () => _buildRecipeListSkeleton(),
              error: (error, stack) => SliverToBoxAdapter(
                child: _LoadError(error: error.toString()),
              ),
            ),
            // Spacing after content
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _BottomActions(
        onCreate: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecipeCreatePage()),
          );
        },
        onAiCreate: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecipeCreatePage(useAi: true)),
          );
        },
      ),
    );
  }

  /// Builds skeleton loading state with 5 placeholder cards
  Widget _buildRecipeListSkeleton() {
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
          return _SkeletonRecipeCard();
        },
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String error;

  const _LoadError({required this.error});

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFF304466), size: 36),
              const SizedBox(height: 12),
              Text(
                'Failed to load recipes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static header with logout button, logo, and search
class _RecipeListHeader extends ConsumerWidget {
  const _RecipeListHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 12),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF304466)),
                tooltip: 'Logout',
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).clear();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ),
          ),
          Image.asset(
            'assets/app_logo_full.png',
            width: 210,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          _buildSearchInput(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF304466)),
      ),
      alignment: Alignment.center,
      child: const TextField(
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          hintText: 'Search Recipe',
          hintStyle: TextStyle(fontSize: 20, color: Color(0xFF706C6C)),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF304466)),
          prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 24),
        ),
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}

/// Recipe list/grid with actual recipe data and search filtering
class _RecipeListContent extends StatefulWidget {
  final List<RecipeModel> recipes;

  const _RecipeListContent({required this.recipes});

  @override
  State<_RecipeListContent> createState() => _RecipeListContentState();
}

class _RecipeListContentState extends State<_RecipeListContent> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<RecipeModel> get _filteredRecipes {
    if (_query.isEmpty) {
      return widget.recipes;
    }

    return widget.recipes
        .where((recipe) => recipe.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = _filteredRecipes;

    if (recipes.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text('No recipes match your search.'),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        itemCount: recipes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 16,
          childAspectRatio: 143 / 174,
        ),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _RecipeCard(
            recipe: recipe,
            imageUrl: recipe.imageUrl,
            statusColor: _statusColor(recipe.healthScore),
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

class _SkeletonRecipeCard extends StatelessWidget {
  const _SkeletonRecipeCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton image - matches 73x73 image container
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Skeleton(
                height: 73,
                width: double.infinity,
                borderRadius: 10,
              ),
            ),
            const SizedBox(height: 7),
            // Skeleton title - 2 lines worth of space
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(
                    height: 14,
                    width: double.infinity,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 6),
                  Skeleton(
                    height: 14,
                    width: 60,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
            // Skeleton status indicator - matches 20x20 circle
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Skeleton(
                  height: 20,
                  width: 20,
                  borderRadius: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final String? imageUrl;
  final Color statusColor;

  const _RecipeCard({
    required this.recipe,
    required this.imageUrl,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
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
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 73,
                  width: double.infinity,
                  child: (imageUrl != null && imageUrl!.isNotEmpty)
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFECECEC),
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_not_supported_outlined),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFECECEC),
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 24 / 1.6, height: 1.2),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback onAiCreate;

  const _BottomActions({
    required this.onCreate,
    required this.onAiCreate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: FloatingActionButton(
              heroTag: 'create',
              backgroundColor: const Color(0xFF8BB3D6),
              elevation: 0,
              onPressed: onCreate,
              child: const Icon(Icons.add, size: 38, color: Colors.white),
            ),
          ),
          SizedBox(
            width: 68,
            height: 68,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(
                side: BorderSide(color: Color(0xFF304466), width: 2),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onAiCreate,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/app_logo.png',
                        width: 38,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const Positioned(
                      right: 14,
                      top: 10,
                      child: Icon(Icons.auto_awesome, color: Color(0xFFFFC857), size: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
