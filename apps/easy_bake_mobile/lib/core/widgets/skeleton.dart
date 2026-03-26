import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A reusable skeleton/placeholder widget using Shimmer effect.
/// Used to display loading states before actual content is loaded.
class Skeleton extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const Skeleton({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
