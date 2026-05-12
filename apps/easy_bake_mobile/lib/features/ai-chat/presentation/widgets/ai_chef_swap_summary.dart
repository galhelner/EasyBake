import 'package:flutter/material.dart';

import 'ingredient_swap_line.dart';

/// Displays a summary of suggested ingredient swaps/substitutions
class AiChefSwapSummary extends StatelessWidget {
  const AiChefSwapSummary({
    required this.title,
    required this.swaps,
    super.key,
  });

  final String title;
  final List<String> swaps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC5DAE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                size: 16,
                color: Color(0xFF2B5D7A),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF21445A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...swaps.map(
            (swap) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IngredientSwapLine(swap),
            ),
          ),
        ],
      ),
    );
  }
}
