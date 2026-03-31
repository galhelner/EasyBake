import 'package:flutter/material.dart';

class CommunityChatRoomPage extends StatelessWidget {
  const CommunityChatRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F7),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _GlowBlob(
                size: 260,
                color: const Color(0xFF8BB3D6).withValues(alpha: 0.22),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: _GlowBlob(
                size: 220,
                color: const Color(0xFF2E4E69).withValues(alpha: 0.12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Image.asset(
                      'assets/app_logo_full.png',
                      width: 210,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFD8E6F1)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F21364A),
                          blurRadius: 22,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFECF4FA),
                            border: Border.all(
                              color: const Color(0xFFC9DDEB),
                              width: 1.3,
                            ),
                          ),
                          child: const Icon(
                            Icons.forum_rounded,
                            size: 34,
                            color: Color(0xFF2E4E69),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDF6ED),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: const Color(0xFFCFE7CF)),
                          ),
                          child: const Text(
                            'Coming Soon',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2F6A38),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Community Chat Room',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF24374D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This feature is coming soon.\nSoon you will be able to share ideas, tips, and recipes with the EasyBake community.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF5D7389),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
