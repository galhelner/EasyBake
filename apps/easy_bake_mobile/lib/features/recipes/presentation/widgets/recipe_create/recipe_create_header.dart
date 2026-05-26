import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class RecipeCreateHeader extends StatelessWidget {
  final VoidCallback onBack;
  final Color primaryColor;
  final String logoAssetPath;
  final bool isEditMode;

  const RecipeCreateHeader({
    super.key,
    required this.onBack,
    required this.primaryColor,
    required this.logoAssetPath,
    this.isEditMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                        l10n.backButtonLabel,
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
          width: 70,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        // Title
        Text(
          isEditMode
              ? l10n.createRecipeHeaderEditTitle
              : l10n.createRecipeHeaderCreateTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 4),
        // Subtitle
        Text(
          isEditMode
            ? l10n.createRecipeHeaderEditSubtitle
            : l10n.createRecipeHeaderCreateSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: primaryColor.withValues(alpha: 0.6),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
