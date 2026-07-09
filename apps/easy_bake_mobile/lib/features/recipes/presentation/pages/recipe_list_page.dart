import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../ai-chat/data/services/chat_service.dart';
import '../../../ai-chat/presentation/pages/ai_chef_chat_popup_page.dart';
import '../../data/services/recipe_service.dart';
import '../../domain/models/recipe_model.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../widgets/bottom_actions.dart';
import '../widgets/load_error_sliver.dart';
import '../widgets/recipe_creation_modal.dart';
import '../widgets/recipe_create_loading_dialog.dart';
import '../widgets/recipe_list/deleting_status_card.dart';
import '../widgets/recipe_list/recipe_list_content.dart';
import '../widgets/recipe_list/recipe_list_header.dart';
import '../widgets/recipe_list/recipe_list_skeleton_sliver.dart';
import 'recipe_create_page.dart';
import '../../domain/models/folder_model.dart';

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
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.couldNotCreateRecipeTitle),
        content: Text(l10n.couldNotCreateRecipeMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.okButtonLabel),
          ),
        ],
      ),
    );
  }

  Future<ImageSource?> _selectImageSource() {
    final l10n = AppLocalizations.of(context)!;
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.uploadFromGalleryLabel),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.takeAPictureLabel),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createRecipeFromImage() async {
    final l10n = AppLocalizations.of(context)!;
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
        builder: (_) =>
            RecipeCreateLoadingDialog(message: l10n.creatingYourRecipeMessage),
      );
      loadingDialogShown = true;

      final recipe = await ref
          .read(recipeServiceProvider)
          .createRecipeFromImage(picked.path);

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
    ref.invalidate(foldersListProvider);
  }

  Future<void> _showCreateFolderDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final parentId = ref.read(currentFolderIdProvider);

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l10n.newFolderDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.folderNameHint,
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF8BB3D6)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                l10n.cancelButtonLabel,
                style: const TextStyle(color: Color(0xFF4E677D)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E4E69),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(l10n.addButtonLabel),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty && mounted) {
      var isSaving = true;
      var saveSucceeded = false;
      String? saveErrorMessage;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (ctx, setState) {
            if (isSaving) {
              Future.microtask(() async {
                try {
                  await ref.read(recipeServiceProvider).createFolder(name, parentId);
                  saveSucceeded = true;
                  if (dialogContext.mounted) {
                    setState(() {
                      isSaving = false;
                    });
                  }
                  if (mounted) {
                    ref.invalidate(foldersListProvider);
                  }
                } catch (error) {
                  saveSucceeded = false;
                  saveErrorMessage = error.toString();
                  if (dialogContext.mounted) {
                    setState(() {
                      isSaving = false;
                    });
                  }
                }
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: DeletingStatusCard(
                isDeleting: isSaving,
                deleteSucceeded: saveSucceeded,
                deleteErrorMessage: saveErrorMessage,
                deletingMessage: l10n.savingFolderMessage,
                deletedMessage: l10n.folderSavedMessage,
                onOk: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            );
          });
        },
      );
    }

    if (mounted) {
      FocusScope.of(context).unfocus();
    }
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

    final currentFolderId = ref.watch(currentFolderIdProvider);

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
                      WidgetsBinding.instance.addPostFrameCallback((_) async {
                        final savedRecipe = await Navigator.of(context).push<RecipeModel>(
                          MaterialPageRoute(
                            builder: (_) => RecipeCreatePage(
                              initialRecipeJson: recipePayload,
                            ),
                          ),
                        );

                        if (savedRecipe != null && context.mounted) {
                          notifyRecipeSaved(savedRecipe.title);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          )
        : null;

    return PopScope(
      canPop: currentFolderId == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final folders = ref.read(foldersListProvider).value ?? [];
        FolderModel? parentFolder;
        for (final f in folders) {
          if (f.id == currentFolderId) {
            parentFolder = f;
            break;
          }
        }
        ref.read(currentFolderIdProvider.notifier).state = parentFolder?.parentId;
      },
      child: MediaQuery(
        data: fixedMediaQuery,
        child: Scaffold(
          backgroundColor: const Color(0xFFEDF1F6),
          resizeToAvoidBottomInset: false,
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Stack(
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
                          await ref.read(foldersListProvider.future);
                        } catch (_) {
                          // Keep RefreshIndicator stable when request fails.
                        }
                      },
                      child: CustomScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.manual,
                        physics: allowPageScroll
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: RecipeListHeader(
                              searchController: _searchController,
                              onSearchChanged: (_) => setState(() {}),
                              onCreateFolder: _showCreateFolderDialog,
                              showSearch: hasAnyRecipes,
                            ),
                          ),
                          if (currentFolderId != null)
                            SliverToBoxAdapter(
                              child: _FolderBreadcrumb(
                                currentFolderId: currentFolderId,
                                onGoBack: (targetId) {
                                  ref.read(currentFolderIdProvider.notifier).state = targetId;
                                },
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
                          const SliverToBoxAdapter(
                            child: SizedBox(height: 110),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              bottomActions ?? const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    ),
  );
  }
}

class _FolderBreadcrumb extends ConsumerWidget {
  final String currentFolderId;
  final ValueChanged<String?> onGoBack;

  const _FolderBreadcrumb({
    required this.currentFolderId,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersListProvider);
    final l10n = AppLocalizations.of(context)!;

    return foldersAsync.maybeWhen(
      data: (folders) {
        final path = <FolderModel>[];
        String? targetId = currentFolderId;
        while (targetId != null) {
          FolderModel? folder;
          for (final f in folders) {
            if (f.id == targetId) {
              folder = f;
              break;
            }
          }
          if (folder == null) break;
          path.insert(0, folder);
          targetId = folder.parentId;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E8ED)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E4E69).withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onGoBack(null),
                    child: Text(
                      l10n.myRecipesLabel,
                      style: const TextStyle(
                        color: Color(0xFF8BB3D6),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  for (int i = 0; i < path.length; i++) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF8BB3D6),
                      ),
                    ),
                    GestureDetector(
                      onTap: i == path.length - 1
                          ? null
                          : () => onGoBack(path[i].id),
                      child: Text(
                        path[i].name,
                        style: TextStyle(
                          color: i == path.length - 1
                              ? const Color(0xFF2E4E69)
                              : const Color(0xFF8BB3D6),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
