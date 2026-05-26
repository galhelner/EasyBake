import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../../auth/presentation/pages/auth_page.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../recipes/presentation/providers/recipe_providers.dart';
import '../widgets/profile_header.dart';
import '../widgets/summary_card.dart';
import '../widgets/preferences_section.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.logoutTitle),
          content: Text(l10n.logoutMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButtonLabel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC44545),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.logoutButtonLabel),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      ref.read(authNotifierProvider.notifier).clear();
      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final authState = ref.watch(authNotifierProvider);
    final recipesAsync = ref.watch(recipesListProvider);
    final fullName = authState.fullName?.trim();
    final userName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : l10n.easyBakeUserFallback;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F7),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.profilePageTitle,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E4E69),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ProfileHeader(userName: userName),
                        const SizedBox(height: 16),
                        SummaryCard(recipesAsync: recipesAsync),
                        const SizedBox(height: 16),
                        const PreferencesSection(),
                        const SizedBox(height: 16),
                        // Logout moved into the scrollable content so it's not sticky
                        ElevatedButton(
                          onPressed: () => _confirmLogout(context, ref),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC44545),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection:
                                isRtl ? TextDirection.rtl : TextDirection.ltr,
                            children: [
                              const Icon(Icons.logout_rounded),
                              const SizedBox(width: 8),
                              Text(
                                l10n.logoutButtonShortLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
