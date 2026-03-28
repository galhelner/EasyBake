import 'package:flutter/material.dart';

import '../../domain/models/recipe_model.dart';
import '../pages/recipe_details_page.dart';

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final String? imageUrl;
  final Color statusColor;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.imageUrl,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecipeDetailsPage(initialRecipe: recipe),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 73,
                  width: double.infinity,
                  child: (imageUrl != null && imageUrl!.isNotEmpty)
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFECECEC),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFECECEC),
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 24 / 1.6, height: 1.2),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
