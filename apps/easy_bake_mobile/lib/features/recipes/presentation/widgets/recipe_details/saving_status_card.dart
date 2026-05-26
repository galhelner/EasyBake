import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import 'recipe_details_theme.dart';

class SavingStatusCard extends StatelessWidget {
  const SavingStatusCard({
    super.key,
    required this.isSaving,
    required this.saveSucceeded,
    this.saveErrorMessage,
    this.onOk,
  });

  final bool isSaving;
  final bool saveSucceeded;
  final String? saveErrorMessage;
  final VoidCallback? onOk;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: 270,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
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
            'assets/app_logo.png',
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          if (isSaving) ...[
            Text(
              l10n.savingYourRecipeMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF2E4E69),
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  kRecipeDetailsPrimaryBlue,
                ),
              ),
            ),
          ] else ...[
            Text(
              saveSucceeded
                  ? l10n.recipeSavedMessage
                  : (saveErrorMessage ?? l10n.couldNotSaveRecipeMessage),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: saveSucceeded ? const Color(0xFF2E4E69) : const Color(0xFFB83232),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onOk ?? () => Navigator.of(context).pop(),
              child: Text(l10n.okButtonLabel),
            ),
          ],
        ],
      ),
    );
  }
}
