import 'package:flutter/material.dart';
import 'dart:typed_data';

class RecipeCreateUploadCard extends StatelessWidget {
  final Color primaryColor;
  final Color backgroundColor;
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const RecipeCreateUploadCard({
    super.key,
    required this.primaryColor,
    required this.backgroundColor,
    required this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          width: 265,
          height: 150,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: CustomPaint(
            painter: const _DashedRRectBorderPainter(
              color: Color(0xFF7A96A2),
              strokeWidth: 2,
              radius: 15,
              dashLength: 6,
              dashGap: 4,
            ),
            child: imageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 64,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Upload Recipe Image',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(imageBytes!, fit: BoxFit.cover),
                        const Align(
                          alignment: Alignment.bottomCenter,
                          child: ColoredBox(
                            color: Color(0x99000000),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Text(
                                'Tap to change photo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  final double dashLength;
  final double dashGap;

  const _DashedRRectBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
    required this.dashLength,
    required this.dashGap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rRect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashLength).clamp(0, metric.length).toDouble();
        final segment = metric.extractPath(distance, next);
        canvas.drawPath(segment, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.dashGap != dashGap;
  }
}
