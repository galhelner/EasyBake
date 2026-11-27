import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class RegisterFormHeader extends StatelessWidget {
  const RegisterFormHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF6FAFF), Color(0xFFDDEBFF)],
            ),
            border: Border.all(
              color: const Color(0xFF8BB3D6).withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E4E69).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 20,
            color: Color(0xFF2E4E69),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.registerHeaderTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F3559),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          l10n.registerHeaderSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: Color(0xFF557089),
          ),
        ),
      ],
    );
  }
}
