import 'package:flutter/material.dart';

class AiChefChatPopupHeader extends StatelessWidget {
  const AiChefChatPopupHeader({
    super.key,
    required this.isCheckingInitialConnection,
    required this.isServiceOnline,
    required this.isRefreshingConnection,
    required this.onRefreshConnection,
    required this.onClose,
  });

  final bool isCheckingInitialConnection;
  final bool isServiceOnline;
  final bool isRefreshingConnection;
  final VoidCallback onRefreshConnection;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEAF2F5), Color(0xFFDCE8EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Color(0xFFD0DCE3))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDFCF8), Color(0xFFFFF0D9)],
              ),
              border: Border.all(
                color: const Color(0xFF2E4E69).withValues(alpha: 0.12),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E4E69).withValues(alpha: 0.18),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.85),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/ai_chef_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EasyBake AI Chef',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF253852),
                    letterSpacing: 0.1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Chat assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF557089),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isCheckingInitialConnection
                  ? const Color(0xFFE3F2FD)
                  : isServiceOnline
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCheckingInitialConnection
                    ? const Color(0xFFD3DADF)
                    : isServiceOnline
                    ? const Color(0xFFA5D6A7)
                    : const Color(0xFFF48FB1),
              ),
            ),
            child: Text(
              isCheckingInitialConnection
                  ? 'Checking...'
                  : isServiceOnline
                  ? 'Online'
                  : 'Offline',
              style: TextStyle(
                fontSize: 11,
                color: isCheckingInitialConnection
                    ? const Color(0xFF6A7884)
                    : isServiceOnline
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFFC2185B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isServiceOnline && !isCheckingInitialConnection) ...[
            const SizedBox(width: 4),
            SizedBox(
              height: 30,
              child: OutlinedButton.icon(
                onPressed: isRefreshingConnection ? null : onRefreshConnection,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDAA4A4)),
                  foregroundColor: const Color(0xFFB93838),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: isRefreshingConnection
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: Color(0xFFB93838),
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 14),
                label: const Text(
                  'Refresh',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFF3C536B),
            ),
          ),
        ],
      ),
    );
  }
}