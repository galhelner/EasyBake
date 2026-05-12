import 'package:flutter/material.dart';

/// Renders a plain text message from AI Chef
class AiChefMessageText extends StatelessWidget {
  const AiChefMessageText(
    this.text, {
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.black,
        height: 1.35,
      ),
    );
  }
}
