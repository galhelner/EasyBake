import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

class DashboardHeroCard extends StatelessWidget {
  const DashboardHeroCard({super.key, required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFFEDF5FB), Color(0xFFE2EEF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFFD4E2EE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF17324B).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/app_logo_full.png',
            height: 56,
            fit: BoxFit.contain,
            alignment: Alignment.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.welcomeUser(displayName),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF17324B),
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
        ],
      ),
    );
  }
}