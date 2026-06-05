import 'package:flutter/material.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.color,
    required this.icon,
    this.imageAsset,
    this.borderColor,
    this.size = 36,
  });

  final Color color;
  final IconData icon;
  final String? imageAsset;
  final Color? borderColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.2)
            : null,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: imageAsset != null
          ? ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(imageAsset!, fit: BoxFit.contain),
              ),
            )
          : Icon(icon, size: 18, color: Colors.white),
    );
  }
}
