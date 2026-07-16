import 'package:flutter/material.dart';

import '../../../../../core/widgets/skeleton.dart';

class DashboardRecipesLoadingState extends StatelessWidget {
  const DashboardRecipesLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 198,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 4),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: 166,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE1EAF4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Skeleton(
                  height: 96,
                  width: double.infinity,
                  borderRadius: 16,
                ),
                const SizedBox(height: 10),
                const Skeleton(
                  height: 14,
                  width: 124,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const Skeleton(
                  height: 10,
                  width: 86,
                  borderRadius: 4,
                ),
                const Spacer(),
                const Skeleton(
                  height: 24,
                  width: 66,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}