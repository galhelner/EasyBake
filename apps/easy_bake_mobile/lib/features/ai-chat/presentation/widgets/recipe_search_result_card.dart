import 'package:flutter/material.dart';

/// Displays a single recipe from search results with health score
class RecipeSearchResultCard extends StatelessWidget {
  const RecipeSearchResultCard({
    required this.title,
    required this.healthScore,
    required this.imageUrl,
    required this.recipe,
    this.showBottomDivider = true,
    required this.onTap,
    super.key,
  });

  final String title;
  final int healthScore;
  final String imageUrl;
  final Map<String, dynamic> recipe;
  final bool showBottomDivider;
  final VoidCallback onTap;

  Color _getHealthColor() {
    if (healthScore >= 70) return const Color(0xFF34C759);
    if (healthScore >= 40) return const Color(0xFFF5B52E);
    return const Color(0xFFFF3B30);
  }

  String _getHealthLabel() {
    if (healthScore >= 70) return 'Healthy';
    if (healthScore >= 40) return 'Average';
    return 'Unhealthy';
  }

  IconData _getHealthIcon() {
    if (healthScore >= 70) {
      return Icons.favorite;
    }
    return Icons.warning_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthColor();
    final healthLabel = _getHealthLabel();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: showBottomDivider
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFE0E6EC), width: 1),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Recipe Image
              SizedBox(
                width: 60,
                height: 60,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFFF0F4F7),
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: const Color(
                                  0xFF8BB3D6,
                                ).withValues(alpha: 0.4),
                                size: 18,
                              ),
                            ),
                          )
                        : Container(
                            color: const Color(0xFFF0F4F7),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: const Color(
                                0xFF8BB3D6,
                              ).withValues(alpha: 0.4),
                              size: 18,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Recipe Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2C3A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: healthColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getHealthIcon(),
                            size: 10,
                            color: healthColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            healthLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: healthColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF7A8D9D),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
