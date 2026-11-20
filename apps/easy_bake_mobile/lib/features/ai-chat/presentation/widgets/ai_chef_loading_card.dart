import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AiChefLoadingCard extends StatelessWidget {
  const AiChefLoadingCard({super.key});

  static const _kPrimaryBlue = Color(0xFF2E4E69);
  static const _kLogoAssetPath = 'assets/app_logo.png';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 230.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFDDEBFF),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17324B).withValues(alpha: 0.12),
            blurRadius: 24.0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            _kLogoAssetPath,
            width: 56.0,
            height: 56.0,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12.0),
          Text(
            l10n.aiChefLoadingChatMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kPrimaryBlue,
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 12.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(999.0),
            child: const LinearProgressIndicator(
              minHeight: 7.0,
              backgroundColor: Color(0xFFDDEBFF),
              valueColor: AlwaysStoppedAnimation<Color>(_kPrimaryBlue),
            ),
          ),
        ],
      ),
    );
  }
}
