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
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 28),
              _TabButton(
                label: 'Ingredients',
                selected: isIngredientsSelected,
                onTap: onIngredientsTap,
              ),
              const SizedBox(width: 28),
              _TabButton(
                label: 'Instructions',
                selected: !isIngredientsSelected,
                onTap: onInstructionsTap,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Container(height: 1, color: kRecipeDetailsPrimaryBlue),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      color: selected ? Colors.white : Colors.black,
      fontSize: 30 / 2,
      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: selected
            ? BoxDecoration(
                color: kRecipeDetailsSelectedTabBackground,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                border: Border.all(color: kRecipeDetailsPrimaryBlue),
              )
            : null,
        alignment: Alignment.center,
        child: Text(label, style: labelStyle),
      ),
    );
  }
}
