import 'package:flutter/material.dart';

import 'ai_chef_chat_button.dart';

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
            width: 68,
            height: 68,
            child: _TapScaleEffect(
              onTap: null,
              child: AiChefChatButton(
                onTap: onAiCreate,
              ),
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
