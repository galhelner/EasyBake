import 'package:flutter/material.dart';

import 'recipe_details_theme.dart';

class RecipeDetailsTabBar extends StatelessWidget {
  const RecipeDetailsTabBar({
    super.key,
    required this.isIngredientsSelected,
    required this.onIngredientsTap,
    required this.onInstructionsTap,
  });

  final bool isIngredientsSelected;
  final VoidCallback onIngredientsTap;
  final VoidCallback onInstructionsTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFE3EDF6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFC2D6E8)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                alignment: isIngredientsSelected
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7BAED5), Color(0xFF5B9ACC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4E7FA8)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Ingredients',
                      icon: Icons.shopping_basket_outlined,
                      selected: isIngredientsSelected,
                      onTap: onIngredientsTap,
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Instructions',
                      icon: Icons.format_list_numbered_rounded,
                      selected: !isIngredientsSelected,
                      onTap: onInstructionsTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected
                    ? Colors.white
                    : kRecipeDetailsPrimaryBlue.withValues(alpha: 0.86),
              ),
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : kRecipeDetailsPrimaryBlue.withValues(alpha: 0.86),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.15,
                ),
                child: Text(label, maxLines: 1, overflow: TextOverflow.fade),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
