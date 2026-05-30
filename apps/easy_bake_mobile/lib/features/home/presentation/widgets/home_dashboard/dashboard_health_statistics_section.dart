import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../../recipes/domain/models/recipe_model.dart';
import 'dashboard_empty_dashboard_card.dart';
import 'dashboard_health_pie_chart_painter.dart';
import 'dashboard_legend_row.dart';
import 'dashboard_types.dart';

class DashboardHealthStatisticsSection extends StatelessWidget {
  const DashboardHealthStatisticsSection({
    super.key,
    required this.l10n,
    required this.recipes,
  });

  final AppLocalizations l10n;
  final List<RecipeModel> recipes;

  @override
  Widget build(BuildContext context) {
    final slices = _buildSlices(recipes);
    final total = recipes.length;

    if (total == 0) {
      return DashboardEmptyCard(
        icon: Icons.pie_chart_outline_rounded,
        title: l10n.dashboardNoHealthStatsTitle,
        subtitle: l10n.dashboardNoHealthStatsSubtitle,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 420;
        final chartSize = isWide ? 164.0 : 180.0;

        final chart = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: chartSize,
              height: chartSize,
              child: CustomPaint(
                size: Size.square(chartSize),
                painter: DashboardHealthPieChartPainter(slices: slices),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.recipeCountLabel(total),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF5E7387).withValues(alpha: 0.95),
              ),
            ),
          ],
        );

        final legend = Column(
          children: slices
              .map(
                (slice) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DashboardLegendRow(slice: slice),
                ),
              )
              .toList(growable: false),
        );

        if (isWide) {
          return Row(
            children: [
              chart,
              const SizedBox(width: 18),
              Expanded(child: legend),
            ],
          );
        }

        return Column(
          children: [
            chart,
            const SizedBox(height: 18),
            legend,
          ],
        );
      },
    );
  }

  List<DashboardHealthSlice> _buildSlices(List<RecipeModel> recipes) {
    final counts = <DashboardRecipeHealthCategory, int>{
      DashboardRecipeHealthCategory.unhealthy: 0,
      DashboardRecipeHealthCategory.average: 0,
      DashboardRecipeHealthCategory.healthy: 0,
    };

    for (final recipe in recipes) {
      counts[dashboardCategoryForScore(recipe.healthScore)] =
          (counts[dashboardCategoryForScore(recipe.healthScore)] ?? 0) + 1;
    }

    final entries = [
      DashboardHealthSlice(
        category: DashboardRecipeHealthCategory.unhealthy,
        label: l10n.unhealthyBadgeLabel,
        count: counts[DashboardRecipeHealthCategory.unhealthy] ?? 0,
        color: const Color(0xFFFF6B6B),
      ),
      DashboardHealthSlice(
        category: DashboardRecipeHealthCategory.average,
        label: l10n.averageBadgeLabel,
        count: counts[DashboardRecipeHealthCategory.average] ?? 0,
        color: const Color(0xFFF5B52E),
      ),
      DashboardHealthSlice(
        category: DashboardRecipeHealthCategory.healthy,
        label: l10n.healthyBadgeLabel,
        count: counts[DashboardRecipeHealthCategory.healthy] ?? 0,
        color: const Color(0xFF34C759),
      ),
    ];

    final total = math.max(1, recipes.length);
    return entries
        .map(
          (slice) => slice.copyWith(
            percent: (slice.count / total) * 100,
          ),
        )
        .toList(growable: false);
  }
}