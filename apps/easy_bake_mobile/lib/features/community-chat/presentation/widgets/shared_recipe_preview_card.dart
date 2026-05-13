import 'package:flutter/material.dart';

class SharedRecipePreviewCard extends StatelessWidget {
  const SharedRecipePreviewCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.healthScore,
    required this.onView,
    required this.onSave,
  });

  final String title;
  final String? imageUrl;
  final int healthScore;
  final VoidCallback onView;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final healthColor = _healthColor(healthScore);
    final healthLabel = _healthLabel(healthScore);
    final healthIcon = _healthIcon(healthScore);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E3F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(13),
                  topRight: Radius.circular(13),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 108,
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: healthColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(healthIcon, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        healthLabel,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF102031),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onView,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('View'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onSave,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: const Color(0xFFE7F0FA),
      child: const Center(
        child: Icon(
          Icons.restaurant_menu_rounded,
          color: Color(0xFF6D87A0),
          size: 28,
        ),
      ),
    );
  }

  Color _healthColor(int score) {
    if (score >= 70) {
      return const Color(0xFF2E7D32);
    }
    if (score >= 40) {
      return const Color(0xFFF9A825);
    }
    return const Color(0xFFC62828);
  }

  String _healthLabel(int score) {
    if (score >= 70) {
      return 'Healthy';
    }
    if (score >= 40) {
      return 'Average';
    }
    return 'Unhealthy';
  }

  IconData _healthIcon(int score) {
    if (score >= 70) {
      return Icons.favorite;
    }
    return Icons.warning_rounded;
  }
}
