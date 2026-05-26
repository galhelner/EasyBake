import 'package:flutter/material.dart';

class RecipeScaleToggle extends StatelessWidget {
  const RecipeScaleToggle({
    super.key,
    required this.currentScale,
    required this.onScaleChanged,
  });

  final double currentScale;
  final ValueChanged<double> onScaleChanged;

  bool get _isPresetScale =>
      currentScale == 1 || currentScale == 2 || currentScale == 3;

  AlignmentGeometry? _getSelectionAlignment() {
    if (currentScale == 1) return AlignmentDirectional.centerStart;
    if (currentScale == 2) return AlignmentDirectional.center;
    if (currentScale == 3) return AlignmentDirectional.centerEnd;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE3EDF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFCBD7E6), width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Stack(
            children: [
              // The animated selection background
              if (_isPresetScale)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: _getSelectionAlignment()!,
                  child: FractionallySizedBox(
                    widthFactor: 1 / 3, // Exactly one third of the width
                    heightFactor: 1.0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E4E69),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              // The labels
              Row(
                children: [
                  _buildScaleButton('x1', 1),
                  _buildScaleButton('x2', 2),
                  _buildScaleButton('x3', 3),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScaleButton(String label, double value) {
    final bool isSelected = currentScale == value;

    return Expanded(
      child: GestureDetector(
        // Makes the entire area clickable, not just the text
        behavior: HitTestBehavior.opaque,
        onTap: () => onScaleChanged(value),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              // Smoothly switch colors based on selection
              color: isSelected ? Colors.white : const Color(0xFF2E4E69),
            ),
          ),
        ),
      ),
    );
  }
}
