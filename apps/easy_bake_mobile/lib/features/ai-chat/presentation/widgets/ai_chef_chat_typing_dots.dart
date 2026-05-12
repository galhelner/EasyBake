import 'package:flutter/material.dart';

class AiChefChatTypingDots extends StatefulWidget {
  const AiChefChatTypingDots({super.key});

  @override
  State<AiChefChatTypingDots> createState() => _AiChefChatTypingDotsState();
}

class _AiChefChatTypingDotsState extends State<AiChefChatTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dot(0.0),
            const SizedBox(width: 5),
            _dot(0.33),
            const SizedBox(width: 5),
            _dot(0.66),
          ],
        );
      },
    );
  }

  Widget _dot(double phase) {
    final value = _controller.value;
    var distance = (value - phase).abs();
    if (distance > 0.5) {
      distance = 1 - distance;
    }

    final opacity = (1 - (distance * 2)).clamp(0.25, 1.0);

    return Opacity(
      opacity: opacity,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFF3A5670),
          shape: BoxShape.circle,
        ),
        child: SizedBox(width: 8, height: 8),
      ),
    );
  }
}