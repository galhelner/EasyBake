import 'dart:async';

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
  static const _loadingWatchdogDuration = Duration(seconds: 18);

  final TextEditingController _searchController = TextEditingController();
  Timer? _loadingWatchdog;
  bool _requiresManualRetry = false;

  void _armLoadingWatchdog() {
    if (_loadingWatchdog != null || _requiresManualRetry) {
      return;
    }
    _loadingWatchdog = Timer(_loadingWatchdogDuration, () {
      if (!mounted) {
        return;
      }
      setState(() {
        _requiresManualRetry = true;
      });
    });
  }

  void _disarmLoadingWatchdog() {
    _loadingWatchdog?.cancel();
    _loadingWatchdog = null;
  }

  void _retryLoad() {
    _disarmLoadingWatchdog();
    setState(() {
      _requiresManualRetry = false;
    });
    ref.invalidate(recipesListProvider);
  }

  @override
  void dispose() {
    _disarmLoadingWatchdog();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = _requiresManualRetry
        ? null
        : ref.watch(recipesListProvider);

    if (!_requiresManualRetry && recipesAsync!.isLoading) {
      _armLoadingWatchdog();
    } else {
      _disarmLoadingWatchdog();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F7),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: RefreshIndicator(
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          onRefresh: () async {
            _retryLoad();
            try {
              await ref.read(recipesListProvider.future);
            } catch (_) {
              // Keep RefreshIndicator stable when request fails.
            }
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
              if (_requiresManualRetry)
                LoadErrorSliver(
                  error:
                      'Server appears offline or unreachable. Start recipe-service and tap Try again.',
                  onRetry: _retryLoad,
                )
              else
                recipesAsync!.when(
                  data: (recipes) => RecipeListContent(
                    recipes: recipes,
                    query: _searchController.text,
                  ),
                  loading: () => const RecipeListSkeletonSliver(),
                  error: (error, stack) => LoadErrorSliver(
                    error: error.toString(),
                    onRetry: _retryLoad,
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
