import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/providers/auth_notifier.dart';
import 'features/recipes/presentation/pages/recipe_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  await container.read(authNotifierProvider.notifier).restoreFromStorage();

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authNotifierProvider).isAuthenticated;

    return MaterialApp(
      title: 'EasyBake',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: isAuthenticated ? const RecipeListPage() : const LoginPage(),
    );
  }
}
