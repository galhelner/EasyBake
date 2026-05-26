import 'package:flutter/material.dart';

import 'ai_chef_chat_bubble.dart';

class AiChefChatButton extends StatelessWidget {
  const AiChefChatButton({
    super.key,
    this.onTap,
    this.logoAssetPath = 'assets/ai_chef_logo.png',
    this.label = 'AI Chef Chat',
  });

  final VoidCallback? onTap;
  final String logoAssetPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            end: -2,
            bottom: 72,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 6 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: AiChefChatBubble(label: label),
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: CircleBorder(
              side: BorderSide(
                color: const Color(0xFF2E4E69).withValues(alpha: 0.12),
                width: 1.2,
              ),
            ),
            child: Container(
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
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.8),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: Center(
                  child: Image.asset(
                    logoAssetPath,
                    width: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}