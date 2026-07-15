import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import 'recipe_details_theme.dart';

class RecipeDetailsHero extends StatelessWidget {
  const RecipeDetailsHero({
    super.key,
    required this.title,
    required this.imageUrl,
    this.recipeBy,
  });

  final String title;
  final String? imageUrl;
  final String? recipeBy;

  @override
  Widget build(BuildContext context) {
    final effectiveImageUrl = (imageUrl != null && imageUrl!.trim().isNotEmpty)
        ? imageUrl!.trim()
        : 'assets/default_recipe.jpg';
    final isNetworkImage = effectiveImageUrl.startsWith('http://') || effectiveImageUrl.startsWith('https://');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: double.infinity,
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isNetworkImage)
                    Image.network(
                      effectiveImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/default_recipe.jpg',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  else
                    Image.asset(
                      effectiveImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFE5E6EA),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            color: kRecipeDetailsPrimaryBlue,
                            size: 34,
                          ),
                        );
                      },
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x750F172A)],
                        stops: [0.45, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF172A3E),
            fontSize: 24,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.25,
          ),
        ),
        if (recipeBy != null && recipeBy!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '${AppLocalizations.of(context)!.recipeAuthorLabel} ${recipeBy!.toLowerCase() == 'ai chef' ? AppLocalizations.of(context)!.aiChefName : recipeBy}',
            style: const TextStyle(
              color: Color(0xFF6E8298),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
