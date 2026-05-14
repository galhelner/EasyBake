import 'package:flutter/material.dart';

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
            const Text(
              'Saving your recipe...',
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
                  ? 'Recipe saved'
                  : (saveErrorMessage ?? 'Could not save recipe. Please try again.'),
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
              child: const Text('OK'),
            ),
          ],
        ],
      ),
    );
  }
}
