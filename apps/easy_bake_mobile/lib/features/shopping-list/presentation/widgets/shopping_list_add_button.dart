import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class ShoppingListAddButton extends StatefulWidget {
  const ShoppingListAddButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<ShoppingListAddButton> createState() => _ShoppingListAddButtonState();
}

class _ShoppingListAddButtonState extends State<ShoppingListAddButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Material(
            color: const Color(0xFF8BB3D6),
            elevation: 4,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onPressed,
              child: Tooltip(
                message: l10n.shoppingListAddItemTitle,
                child: const Center(
                  child: Icon(Icons.add, size: 28, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
