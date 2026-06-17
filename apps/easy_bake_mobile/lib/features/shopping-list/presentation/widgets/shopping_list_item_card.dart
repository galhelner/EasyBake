import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:easy_bake_mobile/features/shopping-list/domain/models/shopping_list_item_model.dart';

class ShoppingListItemCard extends StatelessWidget {
  const ShoppingListItemCard({
    super.key,
    required this.item,
    required this.onToggleChecked,
    required this.onEdit,
    required this.onDelete,
    required this.isEditMode,
    this.dragHandle,
  });

  final ShoppingListItemModel item;
  final ValueChanged<bool> onToggleChecked;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isEditMode;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final checked = item.checked;
    final textColor = checked
        ? const Color(0xFF5D6F69)
        : const Color(0xFF17324B);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: checked ? const Color(0xFFEAF4EC) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: checked ? const Color(0xFFD0E6D4) : const Color(0xFFE4EBF2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => onToggleChecked(!checked),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                Checkbox(
                  value: checked,
                  activeColor: const Color(0xFF5F8E68),
                  onChanged: (value) => onToggleChecked(value ?? false),
                ),
                const SizedBox(width: 6),
                if (item.ingredient.icon.trim().isNotEmpty) ...[
                  _IngredientAvatar(ingredient: item.ingredient),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: isEditMode
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.ingredient.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                decoration: checked
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                decorationColor: const Color(0xFF5D6F69),
                                decorationThickness: 2,
                              ),
                            ),
                            if (item.amount != null && item.amount!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: checked
                                      ? const Color(0xFFD0E6D4)
                                      : const Color(0xFFE6F0FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: checked
                                        ? const Color(0xFFB5D0BC)
                                        : const Color(0xFFD2E3F3),
                                  ),
                                ),
                                child: Text(
                                  item.amount!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: checked
                                        ? const Color(0xFF4A6852)
                                        : const Color(0xFF2F5D7E),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.ingredient.name,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  decoration: checked
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: const Color(0xFF5D6F69),
                                  decorationThickness: 2,
                                ),
                              ),
                            ),
                            if (item.amount != null && item.amount!.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: checked
                                      ? const Color(0xFFD0E6D4)
                                      : const Color(0xFFE6F0FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: checked
                                        ? const Color(0xFFB5D0BC)
                                        : const Color(0xFFD2E3F3),
                                  ),
                                ),
                                child: Text(
                                  item.amount!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: checked
                                        ? const Color(0xFF4A6852)
                                        : const Color(0xFF2F5D7E),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                ),
                if (isEditMode) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFDAE6F5)),
                    ),
                    child: IconButton(
                      onPressed: onEdit,
                      tooltip: l10n.editActionLabel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF2F5D7E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4F4),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF4D1D1)),
                    ),
                    child: IconButton(
                      onPressed: onDelete,
                      tooltip: l10n.deleteActionLabel,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 18,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Color(0xFFD14343),
                      ),
                    ),
                  ),
                  if (dragHandle != null) ...[
                    const SizedBox(width: 8),
                    dragHandle!,
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientAvatar extends StatelessWidget {
  const _IngredientAvatar({required this.ingredient});

  final ShoppingListIngredientModel ingredient;

  @override
  Widget build(BuildContext context) {
    final hasIcon = ingredient.icon.trim().isNotEmpty;
    if (!hasIcon) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(ingredient.icon, style: const TextStyle(fontSize: 20)),
    );
  }
}
