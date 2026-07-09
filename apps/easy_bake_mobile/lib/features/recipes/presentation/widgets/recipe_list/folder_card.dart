import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../domain/models/folder_model.dart';
import '../../providers/recipe_providers.dart';
import '../../../data/services/recipe_service.dart';
import 'move_dialog.dart';
import 'delete_folder_dialog.dart';
import 'deleting_status_card.dart';
import 'delete_confirmation_dialog.dart';

class FolderCard extends ConsumerStatefulWidget {
  final FolderModel folder;
  final bool isListMode;

  const FolderCard({
    super.key,
    required this.folder,
    this.isListMode = false,
  });

  @override
  ConsumerState<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends ConsumerState<FolderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;
  bool _showingOverlay = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _showOverlay() {
    setState(() => _showingOverlay = true);
  }

  void _hideOverlay() {
    setState(() => _showingOverlay = false);
  }

  Future<void> _moveFolder() async {
    _hideOverlay();
    final nextParentId = await showDialog<String?>(
      context: context,
      builder: (ctx) => MoveDialog(
        folderIdToMove: widget.folder.id,
        currentParentId: widget.folder.parentId,
      ),
    );

    if (nextParentId == null || nextParentId == widget.folder.parentId) {
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
      return;
    }

    final targetParentId = nextParentId == '__root__' ? null : nextParentId;

    if (mounted) {
      FocusScope.of(context).unfocus();
      final l10n = AppLocalizations.of(context)!;
      String targetFolderName = '';
      if (targetParentId == null) {
        targetFolderName = l10n.moveToRootOption;
      } else {
        final folders = ref.read(foldersListProvider).value ?? [];
        final folder = folders.firstWhere(
          (f) => f.id == targetParentId,
          orElse: () => FolderModel(
            id: '',
            name: '',
            userId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        targetFolderName = folder.name.isNotEmpty ? folder.name : 'Folder';
      }

      var isMoving = true;
      var moveSucceeded = false;
      String? moveErrorMessage;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(builder: (ctx, setState) {
            if (isMoving) {
              Future.microtask(() async {
                try {
                  await ref.read(recipeServiceProvider).updateFolder(
                        widget.folder.id,
                        parentId: targetParentId,
                        moveToRoot: targetParentId == null,
                      );
                  moveSucceeded = true;
                  if (dialogContext.mounted) {
                    setState(() {
                      isMoving = false;
                    });
                  }
                  if (mounted) {
                    ref.invalidate(foldersListProvider);
                  }
                } catch (error) {
                  moveSucceeded = false;
                  moveErrorMessage = error.toString();
                  if (dialogContext.mounted) {
                    setState(() {
                      isMoving = false;
                    });
                  }
                }
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: DeletingStatusCard(
                isDeleting: isMoving,
                deleteSucceeded: moveSucceeded,
                deleteErrorMessage: moveErrorMessage,
                deletingMessage: l10n.movingFolderMessage(targetFolderName),
                deletedMessage: l10n.folderMovedMessage,
                onOk: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            );
          });
        },
      );
    }
  }

  Future<void> _deleteFolder() async {
    _hideOverlay();

    // Check if the folder is empty
    final recipes = ref.read(recipesListProvider).value ?? [];
    final folders = ref.read(foldersListProvider).value ?? [];
    final folderRecipesCount = recipes.where((r) => r.folderId == widget.folder.id).length;
    final folderSubfoldersCount = folders.where((f) => f.parentId == widget.folder.id).length;
    final isEmpty = folderRecipesCount == 0 && folderSubfoldersCount == 0;

    bool? performDelete;
    bool purgeValue = false;

    if (isEmpty) {
      // If empty, show a simple delete confirmation dialog
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        await showDeleteConfirmationDialog(
          context,
          message: l10n.deleteFolderConfirmationMessage,
          onDelete: () async {
            performDelete = true;
            purgeValue = false;
          },
        );
      }
    } else {
      // If not empty, ask what to do with the contents
      final purge = await showDialog<bool?>(
        context: context,
        builder: (ctx) => const DeleteFolderDialog(),
      );
      if (purge != null) {
        performDelete = true;
        purgeValue = purge;
      }
    }

    if (performDelete == true && mounted) {
      var isDeleting = true;
      var deleteSucceeded = false;
      String? deleteErrorMessage;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final l10n = AppLocalizations.of(dialogContext)!;

          return StatefulBuilder(builder: (ctx, setState) {
            if (isDeleting) {
              Future.microtask(() async {
                try {
                  await ref.read(recipeServiceProvider).deleteFolder(widget.folder.id, purge: purgeValue);
                  deleteSucceeded = true;
                  if (dialogContext.mounted) {
                    setState(() {
                      isDeleting = false;
                    });
                  }
                  if (mounted) {
                    ref.invalidate(foldersListProvider);
                    ref.invalidate(recipesListProvider);
                  }
                } catch (error) {
                  deleteSucceeded = false;
                  deleteErrorMessage = error.toString();
                  if (dialogContext.mounted) {
                    setState(() {
                      isDeleting = false;
                    });
                  }
                }
              });
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              child: DeletingStatusCard(
                isDeleting: isDeleting,
                deleteSucceeded: deleteSucceeded,
                deleteErrorMessage: deleteErrorMessage,
                deletingMessage: l10n.deletingFolderMessage,
                deletedMessage: l10n.folderDeletedMessage,
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final outerBorderRadius = widget.isListMode ? BorderRadius.circular(12) : BorderRadius.circular(16);
    final contentBorderRadius = widget.isListMode ? BorderRadius.circular(12) : BorderRadius.circular(16);

    // Watch items to count recipes and subfolders inside this folder
    final recipesAsync = ref.watch(recipesListProvider);
    final foldersAsync = ref.watch(foldersListProvider);

    int itemsCount = 0;
    recipesAsync.maybeWhen(
      data: (recipes) {
        itemsCount += recipes.where((r) => r.folderId == widget.folder.id).length;
      },
      orElse: () {},
    );
    foldersAsync.maybeWhen(
      data: (folders) {
        itemsCount += folders.where((f) => f.parentId == widget.folder.id).length;
      },
      orElse: () {},
    );

    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -6 * _hoverAnimation.value),
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => _hoverController.forward(),
        onExit: (_) => _hoverController.reverse(),
        child: GestureDetector(
          onTap: () {
            ref.read(currentFolderIdProvider.notifier).state = widget.folder.id;
          },
          onLongPress: _showOverlay,
          child: Container(
            height: widget.isListMode ? 80 : null,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F6FC),
              borderRadius: outerBorderRadius,
              border: Border.all(color: const Color(0xFFD3E3F5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E4E69).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: contentBorderRadius,
                  child: widget.isListMode
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.folder_rounded,
                                size: 40,
                                color: Color(0xFF8BB3D6),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.folder.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F3559),
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.grid_view_rounded,
                                          size: 11,
                                          color: Color(0xFF587185),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          l10n.recipeItemsCount(itemsCount),
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF587185),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xFF8BB3D6),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Centered and Bigger Folder Icon
                              const Center(
                                child: Icon(
                                  Icons.folder_rounded,
                                  size: 42,
                                  color: Color(0xFF8BB3D6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Title
                              Text(
                                widget.folder.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F3559),
                                  height: 1.2,
                                ),
                              ),
                              const Spacer(),
                              // Items counter aligned to the start (left)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.grid_view_rounded,
                                    size: 11,
                                    color: Color(0xFF587185),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      l10n.recipeItemsCount(itemsCount),
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF587185),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
                // Overlay controls (Move / Delete)
                if (_showingOverlay)
                  Positioned.fill(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _hideOverlay,
                          child: ClipRRect(
                            borderRadius: outerBorderRadius,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: outerBorderRadius,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: widget.isListMode ? 2 : 6,
                          right: widget.isListMode ? 8 : 6,
                          child: GestureDetector(
                            onTap: _hideOverlay,
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF4E677D),
                              size: 20,
                            ),
                          ),
                        ),
                        Center(
                          child: widget.isListMode
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: _moveFolder,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2E4E69),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          l10n.moveButtonLabel,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 90,
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: _deleteFolder,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[400],
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          l10n.deleteButtonLabel,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: _moveFolder,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2E4E69),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          l10n.moveButtonLabel,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 90,
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: _deleteFolder,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[400],
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Text(
                                          l10n.deleteButtonLabel,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
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
