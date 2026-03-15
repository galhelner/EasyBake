import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_state.dart';
import 'features/auth/login_page.dart';
import 'features/recipes/recipe_list_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
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
