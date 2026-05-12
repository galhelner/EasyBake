import 'package:flutter/material.dart';

/// Renders a single ingredient swap suggestion (original -> replacement)
class IngredientSwapLine extends StatelessWidget {
  const IngredientSwapLine(
    this.swap, {
    super.key,
  });

  final String swap;

  /// Parses swap text for separators like "->", "=>", "→", " to "
  /// Returns tuple of (original, replacement) or null if parsing fails
  (String, String)? _parseSwapPair(String swap) {
    final separators = ['->', '=>', '→', ' to '];

    for (final separator in separators) {
      final index = separator == ' to '
          ? swap.toLowerCase().indexOf(separator)
          : swap.indexOf(separator);

      if (index <= 0) {
        continue;
      }

      final left = swap.substring(0, index).trim();
      final right = swap.substring(index + separator.length).trim();
      if (left.isEmpty || right.isEmpty) {
        continue;
      }

      return (left, right);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parseSwapPair(swap);

    if (parsed == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD2E1EB)),
        ),
        child: Text(
          swap.trim(),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF17364A),
            height: 1.25,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD2E1EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              parsed.$1,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF335A70),
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: Color(0xFF2B5D7A),
            ),
          ),
          Expanded(
            child: Text(
              parsed.$2,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF17364A),
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
