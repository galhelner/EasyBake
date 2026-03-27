import 'package:flutter/material.dart';

class RecipeCreateHeader extends StatelessWidget {
  final VoidCallback onBack;
  final Color primaryColor;
  final String logoAssetPath;

  const RecipeCreateHeader({
    super.key,
    required this.onBack,
    required this.primaryColor,
    required this.logoAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onBack,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 15, 6, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Image.asset(
            logoAssetPath,
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Create New Recipe',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
