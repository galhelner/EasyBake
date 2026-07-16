import 'package:flutter/material.dart';

/// A generic, reusable toast widget designed to display messages with matching
/// app colors, support a leading logo or icon, and maintain a premium Material 3 silhouette.
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.message,
    this.leading,
    this.backgroundColor,
    this.textColor,
  });

  /// The text message to display in the toast.
  final String message;

  /// An optional leading widget, such as an icon or the app logo image.
  final Widget? leading;

  /// The background color of the toast. Defaults to a bright, premium brand light blue.
  final Color? backgroundColor;

  /// The text color of the toast. Defaults to the dark brand blue.
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFEAF2F9), // Bright brand light blue
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF8BB3D6).withValues(alpha: 0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17324B).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 8),
          ],
          Text(
            message,
            style: TextStyle(
              color: textColor ?? const Color(0xFF0F3559), // Dark brand blue
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
