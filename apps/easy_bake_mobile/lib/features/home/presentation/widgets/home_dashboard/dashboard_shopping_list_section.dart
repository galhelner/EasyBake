import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:easy_bake_mobile/features/shopping-list/domain/models/shopping_list_item_model.dart';
import 'package:easy_bake_mobile/features/shopping-list/data/services/shopping_list_service.dart';
import 'package:easy_bake_mobile/features/shopping-list/presentation/providers/shopping_list_providers.dart';

class DashboardShoppingListSection extends ConsumerWidget {
  const DashboardShoppingListSection({
    super.key,
    required this.items,
  });

  final List<ShoppingListItemModel> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final optimisticChecked = ref.watch(shoppingListOptimisticCheckedProvider);

    Future<void> toggleChecked(ShoppingListItemModel item, bool checked) async {
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.shoppingListItemUpdateFailedMessage)),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          (() {
            final item = items[index];
            final isChecked = optimisticChecked[item.id] ?? item.checked;
            final textColor = isChecked
                ? const Color(0xFF5D6F69)
                : const Color(0xFF17324B);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => toggleChecked(item, !isChecked),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isChecked ? const Color(0xFFEAF4EC) : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isChecked
                          ? const Color(0xFF5F8E68).withValues(alpha: 0.3)
                          : const Color(0xFFDCE7F1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: isChecked,
                          activeColor: const Color(0xFF5F8E68),
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: isChecked
                                ? const Color(0xFF5F8E68)
                                : const Color(0xFF2B3D5A),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (value) => toggleChecked(item, value ?? false),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(
                            horizontal: -4,
                            vertical: -4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (item.ingredient.icon.trim().isNotEmpty) ...[
                        Text(
                          item.ingredient.icon.trim(),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.ingredient.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: isChecked
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
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? const Color(0xFFD0E6D4)
                                      : const Color(0xFFE6F0FA),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isChecked
                                        ? const Color(0xFFB5D0BC)
                                        : const Color(0xFFD2E3F3),
                                  ),
                                ),
                                child: Text(
                                  item.amount!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isChecked
                                        ? const Color(0xFF4A6852)
                                        : const Color(0xFF2F5D7E),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          })(),
          if (index != items.length - 1)
            const SizedBox(height: 8),
        ],
      ],
    );
  }
}
