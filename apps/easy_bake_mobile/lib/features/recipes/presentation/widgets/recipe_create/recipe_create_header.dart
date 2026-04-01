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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back button
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0F5).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onBack,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Back',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Logo
        Image.asset(
          logoAssetPath,
          width: 90,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        // Title
        Text(
          'Create New Recipe',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        // Subtitle
        Text(
          'Share your culinary creation',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryColor.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
