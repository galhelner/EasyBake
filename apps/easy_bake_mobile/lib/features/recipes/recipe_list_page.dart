import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import '../auth/login_page.dart';
import 'recipe_create_page.dart';
import 'domain/recipe_model.dart';
import 'recipe_service.dart';

class RecipeListPage extends ConsumerWidget {
  const RecipeListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              ref.read(authNotifierProvider.notifier).clear();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: recipesAsync.when(
        data: (recipes) => _RecipesList(recipes: recipes),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Failed to load recipes: $error'),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'generate',
            icon: const Icon(Icons.auto_awesome),
            label: const Text('AI create'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecipeCreatePage(useAi: true)),
              );
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'create',
            child: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecipeCreatePage()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RecipesList extends ConsumerWidget {
  final List<RecipeModel> recipes;

  const _RecipesList({required this.recipes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recipes.isEmpty) {
      return const Center(
        child: Text('No recipes yet. Tap + to add one.'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(recipesListProvider);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: recipes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Card(
            child: ListTile(
              title: Text(recipe.title),
              subtitle: Text('Health: ${recipe.healthScore}'),
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
            ),
          );
        },
      ),
    );
  }
}
