import 'package:flutter/material.dart';

import '../../../../../core/widgets/skeleton.dart';

class RecipeDetailsSkeleton extends StatelessWidget {
  const RecipeDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Skeleton(height: 24, width: 74, borderRadius: 6),
          SizedBox(height: 14),
          Skeleton(height: 217, width: double.infinity, borderRadius: 10),
          SizedBox(height: 24),
          Skeleton(height: 36, width: 240, borderRadius: 8),
          SizedBox(height: 28),
          Row(
            children: [
              SizedBox(width: 28),
              Skeleton(height: 46, width: 142, borderRadius: 15),
              SizedBox(width: 28),
              Skeleton(height: 22, width: 120, borderRadius: 8),
            ],
          ),
          SizedBox(height: 2),
          Skeleton(height: 1, width: double.infinity, borderRadius: 0),
          SizedBox(height: 22),
          _SkeletonIngredientRow(),
          SizedBox(height: 14),
          _SkeletonIngredientRow(),
          SizedBox(height: 14),
          _SkeletonIngredientRow(),
          SizedBox(height: 14),
          _SkeletonIngredientRow(),
        ],
      ),
    );
  }
}

class _SkeletonIngredientRow extends StatelessWidget {
  const _SkeletonIngredientRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Skeleton(height: 30, width: 30, borderRadius: 2),
        SizedBox(width: 10),
        Expanded(child: Skeleton(height: 20, borderRadius: 6)),
      ],
    );
  }
}
