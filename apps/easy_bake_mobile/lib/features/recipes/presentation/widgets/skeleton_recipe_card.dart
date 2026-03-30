import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';

class SkeletonRecipeCard extends StatelessWidget {
  const SkeletonRecipeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
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
              // Image placeholder
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: const Skeleton(
                  height: 100,
                  width: double.infinity,
                  borderRadius: 0,
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title lines
                      const Skeleton(height: 14, width: double.infinity, borderRadius: 4),
                      const SizedBox(height: 6),
                      const Skeleton(height: 14, width: 80, borderRadius: 4),
                      const SizedBox(height: 8),
                      // Info chips
                      Row(
                        children: [
                          const Expanded(
                            child: Skeleton(height: 28, width: double.infinity, borderRadius: 6),
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Skeleton(height: 28, width: double.infinity, borderRadius: 6),
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
    );
  }
}
