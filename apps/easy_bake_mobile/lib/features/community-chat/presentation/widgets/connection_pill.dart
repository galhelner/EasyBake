import 'package:flutter/material.dart';

class ConnectionPill extends StatelessWidget {
  const ConnectionPill({
    super.key,
    required this.isConnecting,
    required this.isConnected,
  });

  final bool isConnecting;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    if (isConnecting) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFE8F5E9) : const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isConnected ? const Color(0xFFA5D6A7) : const Color(0xFFF48FB1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isConnected ? const Color(0xFF2E7D32) : const Color(0xFFC2185B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isConnected ? const Color(0xFF2E7D32) : const Color(0xFFC2185B),
            ),
          ),
        ],
      ),
    );
  }
}
