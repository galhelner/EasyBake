import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

enum DashboardRecipeHealthCategory { unhealthy, average, healthy }

class DashboardHealthSlice {
  const DashboardHealthSlice({
    required this.category,
    required this.label,
    required this.count,
    required this.color,
    this.percent = 0,
  });

  final DashboardRecipeHealthCategory category;
  final String label;
  final int count;
  final Color color;
  final double percent;

  DashboardHealthSlice copyWith({double? percent}) {
    return DashboardHealthSlice(
      category: category,
      label: label,
      count: count,
      color: color,
      percent: percent ?? this.percent,
    );
  }
}

Color dashboardStatusColor(int healthScore) {
  if (healthScore >= 70) {
    return const Color(0xFF34C759);
  }
  if (healthScore >= 40) {
    return const Color(0xFFF5B52E);
  }
  return const Color(0xFFFF6B6B);
}

DashboardRecipeHealthCategory dashboardCategoryForScore(int healthScore) {
  if (healthScore >= 70) {
    return DashboardRecipeHealthCategory.healthy;
  }
  if (healthScore >= 40) {
    return DashboardRecipeHealthCategory.average;
  }
  return DashboardRecipeHealthCategory.unhealthy;
}

String dashboardHealthLabel(AppLocalizations l10n, int healthScore) {
  if (healthScore >= 70) {
    return l10n.healthyBadgeLabel;
  }
  if (healthScore >= 40) {
    return l10n.averageBadgeLabel;
  }
  return l10n.unhealthyBadgeLabel;
}