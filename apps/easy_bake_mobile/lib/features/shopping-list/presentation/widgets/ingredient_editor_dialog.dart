import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/features/recipes/data/services/recipe_service.dart';
import 'package:easy_bake_mobile/features/recipes/domain/models/ingredient_suggestion_model.dart';

class IngredientEditorDialog extends StatefulWidget {
  const IngredientEditorDialog({
    super.key,
    required this.title,
    required this.initialValue,
    required this.confirmLabel,
    required this.recipeService,
    required this.onConfirm,
  });

  final String title;
  final String initialValue;
  final String confirmLabel;
  final RecipeService recipeService;
  final Future<void> Function(String) onConfirm;

  @override
  State<IngredientEditorDialog> createState() => _IngredientEditorDialogState();
}

class _IngredientEditorDialogState extends State<IngredientEditorDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  Timer? _debounce;
  List<IngredientSuggestionModel> _suggestions = const [];
  bool _loadingSuggestions = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
    _loadSuggestions(_controller.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions(String value) async {
    _debounce?.cancel();

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 260), () async {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingSuggestions = true;
      });

      try {
        final suggestions = await widget.recipeService
            .fetchIngredientSuggestions(trimmed);
        if (!mounted) {
          return;
        }
        setState(() {
          _suggestions = suggestions;
          _loadingSuggestions = false;
        });
      } catch (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _suggestions = const [];
          _loadingSuggestions = false;
        });
      }
    });
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    if (value.isEmpty || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.onConfirm(value);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Center(
          child: SingleChildScrollView(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
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
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF2E4E69),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          minLines: 1,
                          maxLines: 3,
                          keyboardType: TextInputType.multiline,
                          onChanged: (value) {
                            setState(() {});
                            _loadSuggestions(value);
                          },
                          onSubmitted: (_) => _submit(),
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                             isDense: true,
                             contentPadding: EdgeInsets.symmetric(
                               horizontal: 12,
                               vertical: 10,
                             ),
                             border: OutlineInputBorder(),
                          ),
                        ),
                      ),

                      if (_loadingSuggestions) ...[
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(
                          minHeight: 2,
                          color: Color(0xFF2F5D7E),
                        ),
                      ],
                      if (_suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE4EBF2)),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 120),
                            child: Material(
                              color: Colors.transparent,
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final suggestion = _suggestions[index];
                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                                      leading: suggestion.icon.trim().isEmpty
                                          ? null
                                          : Text(
                                              suggestion.icon,
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                      title: Text(
                                        suggestion.name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      onTap: () {
                                        _debounce?.cancel();
                                        final hasIcon = suggestion.icon.trim().isNotEmpty;
                                        final textValue = hasIcon
                                            ? '${suggestion.icon.trim()} ${suggestion.name}'
                                            : suggestion.name;
                                        _controller.text = textValue;
                                        _controller.selection = TextSelection.collapsed(
                                          offset: textValue.length,
                                        );
                                        setState(() {
                                          _suggestions = const [];
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _controller.text.trim().isEmpty || _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8BB3D6),
                            foregroundColor: Colors.white,
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(widget.confirmLabel),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      splashRadius: 20,
                      padding: const EdgeInsets.all(6),
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF6E8298)),
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(),
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
