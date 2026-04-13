import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../ai-chat/data/services/chat_service.dart';
import '../../../ai-chat/presentation/widgets/ai_chef_chat_popup_dialog.dart';
import '../../data/services/recipe_service.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../widgets/bottom_actions.dart';
import '../widgets/load_error_sliver.dart';
import '../widgets/recipe_creation_modal.dart';
import '../widgets/recipe_create_loading_dialog.dart';
import '../widgets/recipe_list/recipe_list_content.dart';
import '../widgets/recipe_list/recipe_list_header.dart';
import '../widgets/recipe_list/recipe_list_skeleton_sliver.dart';
import 'recipe_create_page.dart';

class RecipeListPage extends ConsumerStatefulWidget {
  const RecipeListPage({super.key, this.showBottomActions = true});

  final bool showBottomActions;

  @override
  ConsumerState<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends ConsumerState<RecipeListPage> {
  static const _loadingWatchdogDuration = Duration(seconds: 50);

  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _loadingWatchdog;
  bool _requiresManualRetry = false;

  Future<void> _showCreateFromImageErrorDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Could not create recipe'),
        content: const Text(
          'We could not create a recipe from this image. Please try again or use another image.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<ImageSource?> _selectImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from Gallery'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Picture'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createRecipeFromImage() async {
    final source = await _selectImageSource();
    if (!mounted || source == null) {
      return;
    }

    var loadingDialogShown = false;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1600,
      );
      if (!mounted || picked == null) {
        return;
      }

      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const RecipeCreateLoadingDialog(
          message: 'Creating your recipe...',
        ),
      );
      loadingDialogShown = true;

      final recipe = await ref.read(recipeServiceProvider).createRecipeFromImage(picked.path);

      if (!mounted) {
        return;
      }

      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
        loadingDialogShown = false;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeCreatePage(initialRecipe: recipe),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      if (loadingDialogShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await _showCreateFromImageErrorDialog();
    }
  }

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
    final mediaQuery = MediaQuery.of(context);
    final fixedMediaQuery = mediaQuery.copyWith(viewInsets: EdgeInsets.zero);
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

    final bottomActions = widget.showBottomActions
        ? Positioned(
            left: 20,
            right: 20,
        bottom: fixedMediaQuery.padding.bottom + 12,
            child: BottomActions(
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
                  onCreateFromImage: _createRecipeFromImage,
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
            ),
          )
        : null;

    return MediaQuery(
      data: fixedMediaQuery,
      child: Scaffold(
        backgroundColor: const Color(0xFFEDF1F6),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            SafeArea(
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
            bottomActions ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
