import 'package:flutter/material.dart';

import 'recipe_details_theme.dart';

class RecipeDetailsAiAssistantButton extends StatelessWidget {
  const RecipeDetailsAiAssistantButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF304466), width: 2),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap ?? () {},
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Image.asset(
                  kRecipeDetailsLogoAssetPath,
                  width: 38,
                  fit: BoxFit.contain,
                ),
              ),
              const Positioned(
                right: 14,
                top: 10,
                child: Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFFC857),
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
