import 'package:flutter/material.dart';

import '../../../chat/presentation/widgets/ai_chef_chat_bubble.dart';

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
          // Create Recipe Button
          SizedBox(
            width: 56,
            height: 56,
            child: FloatingActionButton(
              heroTag: 'create',
              backgroundColor: const Color(0xFF8BB3D6),
              elevation: 4,
              onPressed: onCreate,
              shape: const CircleBorder(),
              child: const Icon(
                Icons.add,
                size: 28,
                color: Colors.white,
              ),
            ).withHoverEffect(),
          ),
          // AI Chef Button
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 0,
                  bottom: 70,
                  child: const AiChefChatBubble(),
                ),
                Material(
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
                    onTap: onAiCreate ?? () {},
                    child: Center(
                      child: Image.asset(
                        'assets/app_logo.png',
                        width: 32,
                        fit: BoxFit.contain,
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

extension FloatingActionButtonHoverEffect on Widget {
  Widget withHoverEffect() {
    return _FloatingActionButtonWithHover(child: this);
  }
}

class _FloatingActionButtonWithHover extends StatefulWidget {
  final Widget child;

  const _FloatingActionButtonWithHover({required this.child});

  @override
  State<_FloatingActionButtonWithHover> createState() =>
      _FloatingActionButtonWithHoverState();
}

class _FloatingActionButtonWithHoverState
    extends State<_FloatingActionButtonWithHover>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _animation,
        child: widget.child,
      ),
    );
  }
}
