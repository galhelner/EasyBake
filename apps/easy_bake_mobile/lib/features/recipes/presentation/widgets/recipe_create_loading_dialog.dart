import 'package:flutter/material.dart';

class RecipeCreateLoadingDialog extends StatelessWidget {
  const RecipeCreateLoadingDialog({
    super.key,
    required this.message,
  });

  final String message;

  static const _kPrimaryBlue = Color(0xFF2E4E69);
  static const _kLogoAssetPath = 'assets/app_logo.png';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.24),
      child: Center(
        child: Container(
          width: 230,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _kLogoAssetPath,
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: const TextStyle(
                  color: _kPrimaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  minHeight: 7,
                  backgroundColor: Color(0xFFD7E6F1),
                  valueColor: AlwaysStoppedAnimation<Color>(_kPrimaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
