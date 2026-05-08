import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/pages/auth_page.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../recipes/presentation/providers/recipe_providers.dart';
import '../widgets/profile_header.dart';
import '../widgets/summary_card.dart';
import '../widgets/preferences_section.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('Are you sure you want to log out of EasyBake?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC44545),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Logout'),
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
    final authState = ref.watch(authNotifierProvider);
    final recipesAsync = ref.watch(recipesListProvider);
    final fullName = authState.displayName?.trim();
    final userName = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : 'EasyBake User';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Profile',
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD8E4EE)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.upcoming_rounded,
                      color: Color(0xFF2E4E69),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'More profile options will be added soon.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF50667B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
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
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
