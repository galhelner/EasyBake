import 'package:material_ui/material_ui.dart';

/// Renders a plain text message in the AI Chef chat window.
class AiChefMessageText extends StatelessWidget {
  const AiChefMessageText(
    this.text, {
    this.color = const Color(0xFF17324B),
    super.key,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.0,
        color: color,
        height: 1.4,
      ),
    );
  }
}
