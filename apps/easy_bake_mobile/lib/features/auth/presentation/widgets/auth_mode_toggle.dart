import 'package:flutter/material.dart';

class AuthModeToggle extends StatelessWidget {
  const AuthModeToggle({
    super.key,
    required this.isRegister,
    required this.onSignInTap,
    required this.onRegisterTap,
  });

  final bool isRegister;
  final VoidCallback onSignInTap;
  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final indicatorWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: isRegister
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: indicatorWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B75DD).withValues(alpha: 0.16),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _AuthModeTabLabel(
                      label: 'Sign In',
                      selected: !isRegister,
                      onTap: onSignInTap,
                    ),
                  ),
                  Expanded(
                    child: _AuthModeTabLabel(
                      label: 'Register',
                      selected: isRegister,
                      onTap: onRegisterTap,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AuthModeTabLabel extends StatelessWidget {
  const _AuthModeTabLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF1B75DD) : const Color(0xFF304466),
            letterSpacing: 0.2,
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
