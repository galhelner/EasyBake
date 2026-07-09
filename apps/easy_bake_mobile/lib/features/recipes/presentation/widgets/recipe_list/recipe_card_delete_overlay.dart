import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../data/services/recipe_service.dart';
import '../../../domain/models/recipe_model.dart';
import '../../../domain/models/folder_model.dart';
import '../../providers/recipe_providers.dart';
import 'delete_confirmation_dialog.dart';
import 'deleting_status_card.dart';
import 'move_dialog.dart';

class RecipeCardDeleteOverlay extends ConsumerStatefulWidget {
  final RecipeModel recipe;
  final VoidCallback onClose;

  const RecipeCardDeleteOverlay({
    super.key,
    required this.recipe,
    required this.onClose,
  });

  @override
  ConsumerState<RecipeCardDeleteOverlay> createState() =>
      _RecipeCardDeleteOverlayState();
}

class _RecipeCardDeleteOverlayState
    extends ConsumerState<RecipeCardDeleteOverlay> {
  Future<void> _showDeleteConfirmationAndDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final recipeId = widget.recipe.id;
    if (recipeId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deleteRecipeMissingIdMessage),
            backgroundColor: Colors.red,
          ),
        );
        widget.onClose();
      }
      return;
    }

    // Show confirmation dialog first while context is still valid
    if (!mounted) return;

    Future<void>? performDeleteFuture;

    await showDeleteConfirmationDialog(
      context,
      onDelete: () async {
        // After user confirms, perform the delete
        if (!mounted) return;
        performDeleteFuture = _performDelete(recipeId);
        await performDeleteFuture;
      },
    );

    // Wait for deletion to complete if it's still running
    if (performDeleteFuture != null) {
      await performDeleteFuture;
    }

    // After entire deletion flow completes, close the overlay
    if (mounted) {
      FocusScope.of(context).unfocus();
      widget.onClose();
    }
  }

  Future<void> _performDelete(String recipeId) async {
    if (!mounted) return;

    // Show the deleting dialog with status updates
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
                await ref.read(recipeServiceProvider).deleteRecipe(recipeId);
                deleteSucceeded = true;
                if (dialogContext.mounted) {
                  setState(() {
                    isDeleting = false;
                  });
                }
                if (mounted) {
                  ref.invalidate(recipesListProvider);
                }
              } catch (error) {
                deleteSucceeded = false;
                deleteErrorMessage = _userFacingDeleteError(l10n, error);
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
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Center(
              child: DeletingStatusCard(
                isDeleting: isDeleting,
                deleteSucceeded: deleteSucceeded,
                deleteErrorMessage: deleteErrorMessage,
                onOk: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ),
          );
        });
      },
    );
  }

  String _userFacingDeleteError(AppLocalizations l10n, Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic> && data['error'] != null) {
        return data['error'].toString();
      }
      
      if (error.response?.statusCode == 401) {
        return l10n.deleteRecipeUnauthorizedMessage;
      }
      
      if (error.response?.statusCode == 404) {
        return l10n.deleteRecipeNotFoundMessage;
      }
    }
    
    return l10n.couldNotDeleteRecipeMessage;
  }

  Future<void> _moveRecipe() async {
    final nextFolderId = await showDialog<String?>(
      context: context,
      builder: (ctx) => MoveDialog(
        recipeId: widget.recipe.id,
        currentParentId: widget.recipe.folderId,
      ),
    );

    // If the user cancelled (nextFolderId is null or equals current folder id), do nothing.
    if (nextFolderId == null || nextFolderId == widget.recipe.folderId) {
      if (mounted) {
        FocusScope.of(context).unfocus();
        widget.onClose();
      }
      return;
    }

    // Now, nextFolderId is either a target folder's UUID or '__root__'
    final targetFolderId = nextFolderId == '__root__' ? null : nextFolderId;

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      String targetFolderName = '';
      if (targetFolderId == null) {
        targetFolderName = l10n.moveToRootOption;
      } else {
        final folders = ref.read(foldersListProvider).value ?? [];
        final folder = folders.firstWhere(
          (f) => f.id == targetFolderId,
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
                  await ref.read(recipeServiceProvider).moveRecipe(
                        widget.recipe.id!,
                        targetFolderId,
                      );
                  moveSucceeded = true;
                  if (dialogContext.mounted) {
                    setState(() {
                      isMoving = false;
                    });
                  }
                  if (mounted) {
                    ref.invalidate(recipesListProvider);
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
                deletingMessage: l10n.movingRecipeMessage(targetFolderName),
                deletedMessage: l10n.recipeMovedMessage,
                onOk: () {
                  Navigator.of(dialogContext).pop();
                  if (mounted) {
                    FocusScope.of(context).unfocus();
                    widget.onClose();
                  }
                },
              ),
            );
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Positioned.fill(
      child: Stack(
        children: [
          // Blur glass effect (confined to card only)
          // GestureDetector to consume taps and close overlay on tap outside
          GestureDetector(
            onTap: widget.onClose,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          // Close button - top right corner (icon only, no background)
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: widget.onClose,
              child: const Icon(Icons.close, color: Colors.black54, size: 24),
            ),
          ),
          // Action buttons at bottom
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: _moveRecipe,
                      icon: const Icon(Icons.drive_file_move_outlined, size: 16),
                      label: Text(
                        l10n.moveButtonLabel,
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E4E69),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: _showDeleteConfirmationAndDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: Text(
                        l10n.deleteButtonLabel,
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
