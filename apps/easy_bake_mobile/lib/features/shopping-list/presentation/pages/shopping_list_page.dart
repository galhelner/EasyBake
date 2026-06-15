import 'dart:async';

import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../recipes/data/services/recipe_service.dart';
import '../../../recipes/presentation/widgets/recipe_list/delete_confirmation_dialog.dart';
import '../../../recipes/presentation/widgets/recipe_list/deleting_status_card.dart';
import '../../data/services/shopping_list_service.dart';
import '../providers/shopping_list_providers.dart';
import '../../domain/models/shopping_list_item_model.dart';
import '../widgets/shopping_list_add_button.dart';
import '../widgets/shopping_list_empty_state.dart';
import '../widgets/shopping_list_loading_state.dart';
import '../widgets/shopping_list_error_state.dart';
import '../widgets/shopping_list_header_card.dart';
import '../widgets/shopping_list_item_card.dart';
import '../widgets/ingredient_editor_dialog.dart';

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  bool _isEditMode = false;

  Future<void> _refreshList() async {
    ref.invalidate(shoppingListItemsProvider);
  }

  void _showSnackBar(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _addItem() async {
    final l10n = AppLocalizations.of(context)!;
    await _showEditorDialog(
      title: l10n.shoppingListAddItemTitle,
      initialValue: '',
      confirmLabel: l10n.addButtonLabel,
      onConfirm: (ingredientName) async {
        if (ingredientName.isEmpty) return;
        try {
          await ref
              .read(shoppingListServiceProvider)
              .addShoppingListItem(ingredientName: ingredientName);
          ref.invalidate(shoppingListItemsProvider);
        } catch (_) {
          rethrow;
        }
      },
    );
  }

  Future<void> _editItem(ShoppingListItemModel item) async {
    final l10n = AppLocalizations.of(context)!;
    await _showEditorDialog(
      title: l10n.shoppingListEditItemTitle,
      initialValue: item.ingredient.name,
      confirmLabel: l10n.saveButtonLabel,
      onConfirm: (ingredientName) async {
        if (ingredientName.isEmpty) return;
        try {
          await ref
              .read(shoppingListServiceProvider)
              .updateShoppingListItem(id: item.id, ingredientName: ingredientName);
          ref.invalidate(shoppingListItemsProvider);
          _showSnackBar(l10n.shoppingListItemUpdatedMessage);
        } catch (_) {
          _showSnackBar(l10n.shoppingListItemUpdateFailedMessage);
          rethrow;
        }
      },
    );
  }

  Future<void> _toggleChecked(ShoppingListItemModel item, bool checked) async {
    final l10n = AppLocalizations.of(context)!;
    ref.read(shoppingListOptimisticCheckedProvider.notifier).updateState((state) => {
          ...state,
          item.id: checked,
        });

    try {
      await ref
          .read(shoppingListServiceProvider)
          .updateShoppingListItem(id: item.id, checked: checked);
    } catch (_) {
      ref.read(shoppingListOptimisticCheckedProvider.notifier).updateState((state) {
        final newState = Map<String, bool>.from(state);
        newState.remove(item.id);
        return newState;
      });
      _showSnackBar(l10n.shoppingListItemUpdateFailedMessage);
    }
  }

  Future<void> _deleteItem(ShoppingListItemModel item) async {
    final l10n = AppLocalizations.of(context)!;
    await showDeleteConfirmationDialog(
      context,
      message: l10n.confirmDeleteShoppingListItemMessage,
      onDelete: () async {
        await _performDelete(item);
      },
    );
  }

  Future<void> _performDelete(ShoppingListItemModel item) async {
    if (!mounted) return;

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
                await ref
                    .read(shoppingListServiceProvider)
                    .deleteShoppingListItem(item.id);
                deleteSucceeded = true;
                if (dialogContext.mounted) {
                  setState(() {
                    isDeleting = false;
                  });
                }
                ref.invalidate(shoppingListItemsProvider);
              } catch (_) {
                deleteSucceeded = false;
                deleteErrorMessage = l10n.shoppingListItemDeleteFailedMessage;
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
                deletingMessage: l10n.deletingShoppingListItemMessage,
                deletedMessage: l10n.shoppingListItemDeletedMessage,
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

  Future<void> _showEditorDialog({
    required String title,
    required String initialValue,
    required String confirmLabel,
    required Future<void> Function(String) onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return IngredientEditorDialog(
          title: title,
          initialValue: initialValue,
          confirmLabel: confirmLabel,
          recipeService: ref.read(recipeServiceProvider),
          onConfirm: onConfirm,
        );
      },
    );
  }

  Widget _buildEditButton(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isEditMode = !_isEditMode;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isEditMode
                ? const Color(0xFFEAF4EC)
                : const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isEditMode
                  ? const Color(0xFFD0E6D4)
                  : const Color(0xFFDAE6F5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isEditMode ? Icons.check_circle_outline_rounded : Icons.edit_rounded,
                size: 16,
                color: _isEditMode
                    ? const Color(0xFF5F8E68)
                    : const Color(0xFF2F5D7E),
              ),
              const SizedBox(width: 6),
              Text(
                _isEditMode ? l10n.doneLabel : l10n.editActionLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _isEditMode
                      ? const Color(0xFF5F8E68)
                      : const Color(0xFF2F5D7E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shoppingListAsync = ref.watch(shoppingListItemsProvider);
    final optimisticChecked = ref.watch(shoppingListOptimisticCheckedProvider);

    ref.listen<AsyncValue<List<ShoppingListItemModel>>>(
      shoppingListItemsProvider,
      (previous, next) {
        if (next is AsyncData) {
          ref.read(shoppingListOptimisticCheckedProvider.notifier).setState(const {});
          final items = next.value;
          if (items == null || items.isEmpty) {
            if (_isEditMode) {
              setState(() {
                _isEditMode = false;
              });
            }
          }
        }
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButtonLocation: Directionality.of(context) == TextDirection.rtl
          ? FloatingActionButtonLocation.startFloat
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: ShoppingListAddButton(onPressed: _addItem),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minCardHeight = (constraints.maxHeight - 240.0).clamp(150.0, double.infinity);

            return RefreshIndicator(
              onRefresh: _refreshList,
              color: const Color(0xFF17324B),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                children: [
                  ShoppingListHeaderCard(
                    title: l10n.shoppingListPageTitle,
                  ),
                  const SizedBox(height: 16),
                  shoppingListAsync.when(
                    loading: () => const ShoppingListLoadingState(),
                    error: (error, _) => ShoppingListErrorState(
                      message: error.toString().replaceFirst('Exception: ', ''),
                      onRetry: _refreshList,
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return const ShoppingListEmptyState();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: _buildEditButton(context, l10n),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(minHeight: minCardHeight),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE4EBF2)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF17324B).withValues(alpha: 0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: _isEditMode
                                ? ReorderableListView(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    buildDefaultDragHandles: false,
                                    onReorderItem: (oldIndex, newIndex) {
                                      ref
                                          .read(shoppingListItemsProvider.notifier)
                                          .reorderItems(oldIndex, newIndex);
                                    },
                                    children: [
                                      for (var index = 0;
                                          index < items.length;
                                          index++)
                                        Padding(
                                          key: ValueKey(items[index].id),
                                          padding: EdgeInsets.only(
                                            bottom: index == items.length - 1
                                                ? 0
                                                : 10,
                                          ),
                                          child: ShoppingListItemCard(
                                            item: items[index].copyWith(
                                              checked: optimisticChecked[
                                                      items[index].id] ??
                                                  items[index].checked,
                                            ),
                                            onToggleChecked: (value) =>
                                                _toggleChecked(
                                                    items[index], value),
                                            onEdit: () =>
                                                _editItem(items[index]),
                                            onDelete: () =>
                                                _deleteItem(items[index]),
                                            isEditMode: _isEditMode,
                                            dragHandle:
                                                ReorderableDragStartListener(
                                              index: index,
                                              child: const Icon(
                                                Icons.drag_handle_rounded,
                                                color: Color(0xFF8BB3D6),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      for (var index = 0;
                                          index < items.length;
                                          index++) ...[
                                        ShoppingListItemCard(
                                          key: ValueKey(items[index].id),
                                          item: items[index].copyWith(
                                            checked: optimisticChecked[
                                                    items[index].id] ??
                                                items[index].checked,
                                          ),
                                          onToggleChecked: (value) =>
                                              _toggleChecked(
                                                  items[index], value),
                                          onEdit: () => _editItem(items[index]),
                                          onDelete: () =>
                                              _deleteItem(items[index]),
                                          isEditMode: _isEditMode,
                                        ),
                                        if (index != items.length - 1)
                                          const SizedBox(height: 10),
                                      ],
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 80), // Spacer for the FAB
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
