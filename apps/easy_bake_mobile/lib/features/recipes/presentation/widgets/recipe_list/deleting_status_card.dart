import 'package:flutter/material.dart';

const Color kRecipeDetailsPrimaryBlue = Color(0xFF1F6FC9);

class DeletingStatusCard extends StatelessWidget {
  const DeletingStatusCard({
    super.key,
    required this.isDeleting,
    required this.deleteSucceeded,
    this.deleteErrorMessage,
    this.onOk,
  });

  final bool isDeleting;
  final bool deleteSucceeded;
  final String? deleteErrorMessage;
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
          if (isDeleting) ...[
            const Text(
              'Deleting your recipe...',
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
              deleteSucceeded
                  ? 'Recipe deleted'
                  : (deleteErrorMessage ?? 'Could not delete recipe. Please try again.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: deleteSucceeded ? const Color(0xFF2E4E69) : const Color(0xFFB83232),
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
