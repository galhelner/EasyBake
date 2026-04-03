import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/pages/auth_page.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../recipes/domain/models/recipe_model.dart';
import '../../../recipes/presentation/providers/recipe_providers.dart';

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
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEDF5FB), Color(0xFFE2EEF7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: const Color(0xFFD3E2EE)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A1D3347),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2E4E69),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3147),
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Welcome back to EasyBake',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF587085),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SummaryCard(recipesAsync: recipesAsync),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.recipesAsync});

  final AsyncValue<List<RecipeModel>> recipesAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E4EE)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF2E4E69),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: recipesAsync.when(
              data: (recipes) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${recipes.length} saved recipes',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F334A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Your personal recipe collection',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5D7489)),
                  ),
                ],
              ),
              loading: () => const Text(
                'Loading your recipe summary...',
                style: TextStyle(fontSize: 14, color: Color(0xFF5D7489)),
              ),
              error: (_, stackTrace) => const Text(
                'Recipe summary unavailable right now',
                style: TextStyle(fontSize: 14, color: Color(0xFF5D7489)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
