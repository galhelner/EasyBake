import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import 'dashboard_types.dart';

class DashboardLegendRow extends StatelessWidget {
  const DashboardLegendRow({super.key, required this.slice});

  final DashboardHealthSlice slice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final countText = slice.count == 1
        ? l10n.recipeCountLabel(1)
        : l10n.recipeCountLabel(slice.count);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: slice.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: slice.color.withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slice.label,
                style: const TextStyle(
                  color: Color(0xFF17324B),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                countText,
                style: TextStyle(
                  color: const Color(0xFF5E7387).withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${slice.percent.toStringAsFixed(0)}%',
          style: TextStyle(
            color: slice.color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}