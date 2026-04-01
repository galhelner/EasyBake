import 'package:flutter/material.dart';

import '../../../domain/models/recipe_model.dart';
import '../../pages/recipe_details_page.dart';

class RecipeCard extends StatefulWidget {
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
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -8 * _hoverAnimation.value),
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => _hoverController.forward(),
        onExit: (_) => _hoverController.reverse(),
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecipeDetailsPage(initialRecipe: widget.recipe),
              ),
            );
          },
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E4E69).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF2E4E69).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                          child: SizedBox(
                            height: 100,
                            width: double.infinity,
                            child: (widget.imageUrl != null &&
                                    widget.imageUrl!.isNotEmpty)
                                ? Image.network(
                                    widget.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        color: const Color(0xFFF0F4F7),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.image_not_supported_outlined,
                                          color:
                                              const Color(0xFF8BB3D6)
                                                  .withValues(alpha: 0.4),
                                          size: 32,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: const Color(0xFFF0F4F7),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: const Color(0xFF8BB3D6)
                                          .withValues(alpha: 0.4),
                                      size: 32,
                                    ),
                                  ),
                          ),
                        ),
                        // Health Score Badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.statusColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.statusColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getHealthIcon(widget.recipe.healthScore),
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getHealthLabel(widget.recipe.healthScore),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Content Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.recipe.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF20364B),
                                  height: 1.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Recipe ingredients count
                            Row(
                              children: [
                                Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 14,
                                  color: const Color(0xFF2E4E69),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${widget.recipe.ingredients.length} ingredients',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF4E677D),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getHealthLabel(int healthScore) {
    if (healthScore >= 70) {
      return 'Healthy';
    } else if (healthScore >= 40) {
      return 'Average';
    } else {
      return 'Unhealthy';
    }
  }

  IconData _getHealthIcon(int healthScore) {
    if (healthScore >= 70) {
      return Icons.favorite;
    } else {
      return Icons.warning_rounded;
    }
  }
}


