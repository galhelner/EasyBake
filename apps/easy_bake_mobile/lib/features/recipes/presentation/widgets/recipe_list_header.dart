import 'package:flutter/material.dart';

class RecipeListHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool showSearch;

  const RecipeListHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.showSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Image.asset(
              'assets/app_logo_full.png',
              width: 200,
              fit: BoxFit.contain,
            ),
          ),
          if (showSearch) ...[
            const SizedBox(height: 20),
            _SearchInput(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SearchInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchInput({required this.controller, required this.onChanged});

  @override
  State<_SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<_SearchInput> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (isFocused) {
        setState(() {
          _isFocused = isFocused;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused
                ? const Color(0xFF8BB3D6)
                : const Color(0xFFE0E8ED),
            width: _isFocused ? 2 : 1,
          ),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFF8BB3D6).withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF2E4E69).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF20364B),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: 'Search recipes...',
            hintStyle: TextStyle(
              fontSize: 16,
              color: const Color(0xFF4E677D).withValues(alpha: 0.6),
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 8, 0),
              child: Icon(
                Icons.search_rounded,
                color: Color(0xFF8BB3D6),
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 48,
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.clear();
                        widget.onChanged('');
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF8BB3D6),
                        size: 20,
                      ),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 48,
            ),
          ),
        ),
      ),
    );
  }
}
