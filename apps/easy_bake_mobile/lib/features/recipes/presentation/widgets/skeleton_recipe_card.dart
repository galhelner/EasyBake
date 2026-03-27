import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';

class SkeletonRecipeCard extends StatelessWidget {
  const SkeletonRecipeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const Skeleton(
                height: 73,
                width: double.infinity,
                borderRadius: 10,
              ),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Skeleton(height: 14, width: double.infinity, borderRadius: 4),
                  SizedBox(height: 6),
                  Skeleton(height: 14, width: 60, borderRadius: 4),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: const Skeleton(height: 20, width: 20, borderRadius: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
