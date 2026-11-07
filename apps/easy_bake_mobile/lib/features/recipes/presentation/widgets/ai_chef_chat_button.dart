import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'ai_chef_chat_bubble.dart';

class AiChefChatButton extends StatefulWidget {
  const AiChefChatButton({
    super.key,
    this.onTap,
    this.logoAssetPath = 'assets/pierre_portrait.png',
    this.label = 'Ask Pierre',
    this.idleDuration = const Duration(milliseconds: 1800),
  });

  final VoidCallback? onTap;
  final String logoAssetPath;
  final String label;
  final Duration idleDuration;

  @override
  State<AiChefChatButton> createState() => _AiChefChatButtonState();
}

class _AiChefChatButtonState extends State<AiChefChatButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bubbleController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _idleTimer;
  DateTime _lastPointerTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _wasActive = true;
  bool _isTickerEnabled = true;
  bool _isCurrentRoute = true;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _bubbleController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _bubbleController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeIn,
      ),
    );

    GestureBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointerEvent);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showBubbleAndResetTimer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isTickerEnabled = TickerMode.valuesOf(context).enabled;
    _isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    final isActive = _isTickerEnabled && _isCurrentRoute;

    if (isActive && !_wasActive) {
      _showBubbleAndResetTimer();
    } else if (!isActive && _wasActive) {
      _idleTimer?.cancel();
      _bubbleController.value = 0.0;
    }
    _wasActive = isActive;
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _onGlobalPointerEvent,
    );
    _idleTimer?.cancel();
    _bubbleController.dispose();
    super.dispose();
  }

  void _onGlobalPointerEvent(PointerEvent event) {
    if (!mounted) return;
    if (event is! PointerDownEvent &&
        !(event is PointerMoveEvent && event.down)) {
      return;
    }

    final now = DateTime.now();
    if (event is PointerMoveEvent &&
        now.difference(_lastPointerTime).inMilliseconds < 250) {
      return;
    }
    _lastPointerTime = now;

    if (!_isTickerEnabled || !_isCurrentRoute) {
      return;
    }

    _showBubbleAndResetTimer();
  }

  void _showBubbleAndResetTimer() {
    if (!mounted) return;

    _idleTimer?.cancel();

    if (_bubbleController.status != AnimationStatus.completed &&
        _bubbleController.status != AnimationStatus.forward) {
      _bubbleController.forward();
    }

    _idleTimer = Timer(widget.idleDuration, () {
      if (!mounted) return;
      _bubbleController.reverse();
    });
  }

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
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: AiChefChatBubble(label: widget.label),
                ),
              ),
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
                onTap: widget.onTap,
                child: Center(
                  child: Image.asset(
                    widget.logoAssetPath,
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
