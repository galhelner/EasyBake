import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../recipes/domain/models/recipe_model.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.recipesAsync});

  final AsyncValue<List<RecipeModel>> recipesAsync;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E4EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF2E4E69),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: recipesAsync.when(
              data: (recipes) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.summaryCardSavedRecipes(recipes.length),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F334A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.summaryCardSubtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5D7489),
                    ),
                  ),
                ],
              ),
              loading: () => Text(
                l10n.summaryCardLoadingMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D7489),
                ),
              ),
              error: (_, stackTrace) => Text(
                l10n.summaryCardUnavailableMessage,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5D7489),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
