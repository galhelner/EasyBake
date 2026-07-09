import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../../providers/recipe_providers.dart';

class RecipeListHeader extends ConsumerWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool showSearch;
  final VoidCallback onCreateFolder;

  const RecipeListHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onCreateFolder,
    this.showSearch = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDDE7F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E4E69).withValues(alpha: 0.06),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/app_logo.png',
                  width: 38,
                  height: 38,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  l10n.myRecipesLabel,
                  style: const TextStyle(
                    color: Color(0xFF17324B),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          if (showSearch) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _SearchInput(
                    controller: searchController,
                    onChanged: onSearchChanged,
                  ),
                ),
                const SizedBox(width: 12),
                _ViewToggleButton(),
                const SizedBox(width: 12),
                _CreateFolderButton(onPressed: onCreateFolder),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _CreateFolderButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CreateFolderButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: 48,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E8ED), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E4E69).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.create_new_folder_rounded,
                color: Color(0xFF8BB3D6),
                size: 22,
              ),
            ),
          ),
        ),
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
  final FocusNode _focusNode = FocusNode(skipTraversal: true);
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedContainer(
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
        focusNode: _focusNode,
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
          hintText: l10n.searchRecipesHint,
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
    );
  }
}

class _ViewToggleButton extends ConsumerWidget {
  const _ViewToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(recipeViewModeProvider);
    final isListMode = viewMode == 'list';

    return SizedBox(
      height: 48,
      width: 48,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            ref.read(recipeViewModeProvider.notifier).toggle();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E8ED), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E4E69).withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isListMode ? Icons.grid_view_rounded : Icons.list_rounded,
                color: const Color(0xFF8BB3D6),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
