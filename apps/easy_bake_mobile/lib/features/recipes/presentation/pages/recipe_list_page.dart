import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai-chat/data/services/chat_service.dart';
import '../../../ai-chat/presentation/widgets/ai_chef_chat_popup_dialog.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../widgets/bottom_actions.dart';
import '../widgets/load_error_sliver.dart';
import '../widgets/recipe_creation_modal.dart';
import '../widgets/recipe_list_content.dart';
import '../widgets/recipe_list_header.dart';
import '../widgets/recipe_list_skeleton_sliver.dart';
import 'recipe_create_page.dart';

class RecipeListPage extends ConsumerStatefulWidget {
  const RecipeListPage({super.key, this.showBottomActions = true});

  final bool showBottomActions;

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
    final hasAnyRecipes = _requiresManualRetry
        ? true
        : recipesAsync?.maybeWhen(
                data: (recipes) => recipes.isNotEmpty,
                orElse: () => true,
              ) ??
              true;
    final allowPageScroll = _requiresManualRetry || hasAnyRecipes;

    if (!hasAnyRecipes && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    if (!_requiresManualRetry && recipesAsync!.isLoading) {
      _armLoadingWatchdog();
    } else {
      _disarmLoadingWatchdog();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F6),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            color: const Color(0xFF8BB3D6),
            backgroundColor: Colors.white,
            onRefresh: () async {
              _retryLoad();
              try {
                await ref.read(recipesListProvider.future);
              } catch (_) {
                // Keep RefreshIndicator stable when request fails.
              }
            },
            child: CustomScrollView(
              physics: allowPageScroll
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: RecipeListHeader(
                    searchController: _searchController,
                    onSearchChanged: (_) => setState(() {}),
                    showSearch: hasAnyRecipes,
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
                if (allowPageScroll)
                  const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.showBottomActions
          ? BottomActions(
              onCreate: () {
                showRecipeCreationModal(
                  context,
                  onCreateManually: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecipeCreatePage(),
                      ),
                    );
                  },
                  onCreateFromImage: null,
                );
              },
              onAiCreate: () {
                unawaited(
                  showAiChefChatPopup(
                    context,
                    pageContext: 'home',
                    chatService: ref.read(chatServiceProvider),
                    onOpenRecipeCreated: (recipePayload) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecipeCreatePage(
                            initialRecipeJson: recipePayload,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            )
          : null,
    );
  }
}
