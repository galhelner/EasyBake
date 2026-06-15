import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class ShoppingListEmptyState extends StatelessWidget {
  const ShoppingListEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4EBF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: Color(0xFF2F5D7E),
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.shoppingListEmptyTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF17324B),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.shoppingListEmptySubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF60707F),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
