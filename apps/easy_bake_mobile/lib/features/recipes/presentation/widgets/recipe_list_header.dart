import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';

class RecipeListHeader extends ConsumerWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  const RecipeListHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 10),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(right: 12, top: 12),
              child: IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF304466)),
                tooltip: 'Logout',
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).clear();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                },
              ),
            ),
          ),
          Image.asset(
            'assets/app_logo_full.png',
            width: 210,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          _SearchInput(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchInput({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF304466)),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          hintText: 'Search Recipe',
          hintStyle: TextStyle(fontSize: 20, color: Color(0xFF706C6C)),
          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF304466)),
          prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 24),
        ),
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
