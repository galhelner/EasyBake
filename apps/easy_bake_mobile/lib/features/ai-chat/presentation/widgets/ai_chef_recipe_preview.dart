import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

/// Displays a recipe preview card with image and view button
class AiChefRecipePreview extends StatelessWidget {
  const AiChefRecipePreview({
    required this.recipeTitle,
    required this.imageUrl,
    required this.recipePayload,
    required this.onViewRecipe,
    super.key,
  });

  final String recipeTitle;
  final String imageUrl;
  final Map<String, dynamic> recipePayload;
  final VoidCallback onViewRecipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCE8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl.isNotEmpty)
            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(color: const Color(0xFFF5FAFE)),
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFF5FAFE),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Color(0xFFB0C7DB),
                    size: 40,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 160,
              color: const Color(0xFFF5FAFE),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: Color(0xFFB0C7DB),
                size: 40,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  recipeTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A2A3C),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewRecipe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(l10n.viewRecipeButtonLabel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
