import 'package:flutter/material.dart';

import '../../../ai-chat/presentation/widgets/ai_chef_chat_bubble.dart';

class BottomActions extends StatelessWidget {
  final VoidCallback onCreate;
  final VoidCallback? onAiCreate;

  const BottomActions({super.key, required this.onCreate, this.onAiCreate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width - 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: _TapScaleEffect(
              onTap: onCreate,
              child: Material(
                color: const Color(0xFF8BB3D6),
                elevation: 4,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onCreate,
                  child: const Center(
                    child: Icon(Icons.add, size: 28, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 0,
                  bottom: 70,
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
                    child: const AiChefChatBubble(),
                  ),
                ),
                _TapScaleEffect(
                  onTap: onAiCreate,
                  child: Material(
                    color: Colors.white,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: const Color(0xFF2E4E69).withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    elevation: 4,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onAiCreate,
                      child: Center(
                        child: Image.asset(
                          'assets/ai_chef_logo.png',
                          width: 32,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
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

class _TapScaleEffect extends StatefulWidget {
  const _TapScaleEffect({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_TapScaleEffect> createState() => _TapScaleEffectState();
}

class _TapScaleEffectState extends State<_TapScaleEffect> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
