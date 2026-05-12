import 'package:flutter/material.dart';

class AiChefChatBubble extends StatelessWidget {
  const AiChefChatBubble({super.key, this.label = 'AI Chef Chat'});

  final String label;

  @override
  Widget build(BuildContext context) {
    const bubbleColor = Color(0xFFF5D0A6);
    const borderColor = Color(0xFFD1A373);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E4E69).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1E2630),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(-12, -1),
          child: SizedBox(
            width: 14,
            height: 10,
            child: CustomPaint(
              painter: _BubbleTailPainter(
                fillColor: bubbleColor,
                borderColor: borderColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({
    required this.fillColor,
    required this.borderColor,
  });

  final Color fillColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.72, size.height)
      ..close();

    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final borderPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.72, size.height)
      ..lineTo(0, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}
