import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/providers/recipe_providers.dart';
import '../widgets/bottom_actions.dart';
import '../widgets/load_error_sliver.dart';
import '../widgets/recipe_list_content.dart';
import '../widgets/recipe_list_header.dart';
import '../widgets/recipe_list_skeleton_sliver.dart';
import 'recipe_create_page.dart';

class RecipeListPage extends ConsumerStatefulWidget {
  const RecipeListPage({super.key});

  @override
  ConsumerState<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends ConsumerState<RecipeListPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              SliverToBoxAdapter(
                child: RecipeListHeader(
                  searchController: _searchController,
                  onSearchChanged: (_) => setState(() {}),
                ),
              ),
              recipesAsync.when(
                data: (recipes) => RecipeListContent(
                  recipes: recipes,
                  query: _searchController.text,
                ),
                loading: () => const RecipeListSkeletonSliver(),
                error: (error, stack) => SliverToBoxAdapter(
                  child: LoadErrorSliver(error: error.toString()),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: BottomActions(
        onCreate: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RecipeCreatePage()));
        },
      ),
    );
  }
}
