import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai-chat/data/services/chat_service.dart';
import '../../../ai-chat/presentation/widgets/ai_chef_chat_popup_dialog.dart';
import '../../data/services/recipe_service.dart';
import '../../domain/models/recipe_model.dart';
import '../providers/recipe_providers.dart';
import '../widgets/recipe_details/recipe_details_ai_assistant_button.dart';
import '../widgets/recipe_details/recipe_details_hero.dart';
import '../widgets/recipe_details/recipe_details_ingredient_list.dart';
import '../widgets/recipe_details/recipe_details_instruction_list.dart';
import '../widgets/recipe_details/recipe_details_skeleton.dart';
import '../widgets/recipe_details/recipe_details_tab_bar.dart';
import '../widgets/recipe_details/recipe_details_theme.dart';
import '../widgets/recipe_details/recipe_details_top_bar.dart';
import 'recipe_create_page.dart';

enum _RecipeDetailTab { ingredients, instructions }

enum _RecipeAction { edit, delete }

class RecipeDetailsPage extends ConsumerStatefulWidget {
  final RecipeModel initialRecipe;

  const RecipeDetailsPage({super.key, required this.initialRecipe});

  @override
  ConsumerState<RecipeDetailsPage> createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends ConsumerState<RecipeDetailsPage> {
  static const _kLogoAssetPath = 'assets/app_logo.png';

  late RecipeModel _recipe;
  _RecipeDetailTab _selectedTab = _RecipeDetailTab.ingredients;
  bool _isRefreshing = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.initialRecipe;
    _refreshRecipeData();
  }

  Future<void> _refreshRecipeData() async {
    final id = _recipe.id;
    if (id == null || id.isEmpty) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      final service = ref.read(recipeServiceProvider);
      final updated = await service.fetchRecipeById(id);
      if (!mounted) {
        return;
      }
      setState(() {
        _recipe = updated;
      });
    } catch (_) {
      // Keep initial card data visible if refresh fails.
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _handleRecipeAction(_RecipeAction action) async {
    switch (action) {
      case _RecipeAction.edit:
        await _openEditRecipePage();
        return;
      case _RecipeAction.delete:
        await _confirmAndDelete();
    }
  }

  Future<void> _handleMenuAction(String action) async {
    if (action == 'edit') {
      await _handleRecipeAction(_RecipeAction.edit);
      return;
    }
    if (action == 'delete') {
      await _handleRecipeAction(_RecipeAction.delete);
    }
  }

  Future<void> _openEditRecipePage() async {
    final updatedRecipe = await Navigator.of(context).push<RecipeModel>(
      MaterialPageRoute(
        builder: (_) => RecipeCreatePage(initialRecipe: _recipe),
      ),
    );

    if (!mounted || updatedRecipe == null) {
      return;
    }

    setState(() {
      _recipe = updatedRecipe;
    });

    ref.invalidate(recipesListProvider);
  }

  Future<void> _confirmAndDelete() async {
    final id = _recipe.id;
    if (id == null || id.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This recipe cannot be deleted yet.')),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Recipe?'),
          content: const Text(
            'This action cannot be undone. Do you want to delete this recipe?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(recipeServiceProvider).deleteRecipe(id);
      ref.invalidate(recipesListProvider);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      final status = error.response?.statusCode;
      final message = status == 404
          ? 'Recipe not found. It may have already been deleted.'
          : 'Could not delete recipe. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete recipe. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = _recipe.ingredients;
    final instructions = _recipe.instructions;

    return Scaffold(
      backgroundColor: kRecipeDetailsPageBackground,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: RecipeDetailsAiAssistantButton(
        onTap: () {
          showAiChefChatPopup(
            context,
            pageContext: 'recipe_detail',
            recipeId: _recipe.id,
            chatService: ref.read(chatServiceProvider),
            onOpenRecipeCreated: (recipePayload) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      RecipeCreatePage(initialRecipeJson: recipePayload),
                ),
              );
            },
          );
        },
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_isRefreshing)
              const RecipeDetailsSkeleton()
            else ...[
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 180),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecipeDetailsTopBar(
                      onBack: () => Navigator.of(context).maybePop(),
                      onMenuSelected: _handleMenuAction,
                      isMenuDisabled: _isDeleting,
                    ),
                    const SizedBox(height: 14),
                    RecipeDetailsHero(
                      title: _recipe.title,
                      imageUrl: _recipe.imageUrl,
                    ),
                    const SizedBox(height: 28),
                    RecipeDetailsTabBar(
                      isIngredientsSelected:
                          _selectedTab == _RecipeDetailTab.ingredients,
                      onIngredientsTap: () {
                        setState(() {
                          _selectedTab = _RecipeDetailTab.ingredients;
                        });
                      },
                      onInstructionsTap: () {
                        setState(() {
                          _selectedTab = _RecipeDetailTab.instructions;
                        });
                      },
                    ),
                    const SizedBox(height: 22),
                    if (_selectedTab == _RecipeDetailTab.ingredients)
                      RecipeDetailsIngredientList(
                        items: ingredients,
                        iconsByName: _recipe.ingredientIcons,
                        amountsByName: _recipe.ingredientAmounts,
                      )
                    else
                      RecipeDetailsInstructionList(items: instructions),
                  ],
                ),
              ),
            ],
            if (_isDeleting)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.24),
                  child: Center(
                    child: Container(
                      width: 230,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            _kLogoAssetPath,
                            width: 56,
                            height: 56,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Deleting your recipe...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF2E4E69),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: const LinearProgressIndicator(
                              minHeight: 7,
                              backgroundColor: Color(0xFFD7E6F1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                kRecipeDetailsPrimaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
