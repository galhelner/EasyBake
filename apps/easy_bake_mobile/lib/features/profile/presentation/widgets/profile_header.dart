import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String userName;

  const ProfileHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFEDF5FB), Color(0xFFE2EEF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD3E2EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F113257),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2E4E69),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3147),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Welcome back to EasyBake',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF587085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
