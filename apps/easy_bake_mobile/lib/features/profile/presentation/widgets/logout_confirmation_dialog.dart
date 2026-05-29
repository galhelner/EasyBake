import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  static const _kPrimaryBlue = Color(0xFF2E4E69);
  static const _kLogoAssetPath = 'assets/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 270,
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
                    l10n.logoutTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _kPrimaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.logoutMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _kPrimaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimaryBlue,
                            side: const BorderSide(color: Color(0xFFD6E3F2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(l10n.cancelButtonLabel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC44545),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(l10n.logoutButtonLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -4,
              right: -4,
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  splashRadius: 20,
                  padding: const EdgeInsets.all(6),
                  icon: const Icon(
                    Icons.close,
                    size: 20,
                    color: Color(0xFF6E8298),
                  ),
                  onPressed: onCancel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
