import 'package:flutter/material.dart';

class AiChefChatBubble extends StatelessWidget {
  const AiChefChatBubble({super.key, this.label = 'AI Chef Chat'});

  final String label;

  @override
  Widget build(BuildContext context) {
    const bubbleTopColor = Color(0xFFFFE0B5);
    const bubbleBottomColor = Color(0xFFF4C58D);
    const borderColor = Color(0xFFCD985D);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bubbleTopColor, bubbleBottomColor],
            ),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: borderColor.withValues(alpha: 0.85),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E4E69).withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 11,
                  color: Color(0xFF6D451B),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF1E2630),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(-12, -1),
          child: SizedBox(
            width: 14,
            height: 10,
            child: CustomPaint(
              painter: _BubbleTailPainter(
                fillColor: bubbleBottomColor,
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
      ..lineTo(size.width * 0.78, size.height)
      ..close();

    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final borderPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width * 0.78, size.height)
      ..lineTo(0, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor;
  }
}