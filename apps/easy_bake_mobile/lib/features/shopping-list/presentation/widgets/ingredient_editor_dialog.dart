import 'dart:async';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/features/recipes/data/services/recipe_service.dart';
import 'package:easy_bake_mobile/features/recipes/domain/models/ingredient_suggestion_model.dart';

class IngredientEditorDialog extends StatefulWidget {
  const IngredientEditorDialog({
    super.key,
    required this.title,
    required this.initialName,
    required this.initialAmount,
    required this.confirmLabel,
    required this.recipeService,
    required this.onConfirm,
  });

  final String title;
  final String initialName;
  final String initialAmount;
  final String confirmLabel;
  final RecipeService recipeService;
  final Future<void> Function(String name, String amount) onConfirm;

  @override
  State<IngredientEditorDialog> createState() => _IngredientEditorDialogState();
}

class _IngredientEditorDialogState extends State<IngredientEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final FocusNode _nameFocusNode;
  late final FocusNode _amountFocusNode;
  Timer? _debounce;
  List<IngredientSuggestionModel> _suggestions = const [];
  bool _loadingSuggestions = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _amountController = TextEditingController(text: widget.initialAmount);
    _nameFocusNode = FocusNode();
    _amountFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
    _loadSuggestions(_nameController.text);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _amountController.dispose();
    _nameFocusNode.dispose();
    _amountFocusNode.dispose();
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
    final name = _nameController.text.trim();
    final amount = _amountController.text.trim();
    if (name.isEmpty || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.onConfirm(name, amount);
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
    final l10n = AppLocalizations.of(context)!;

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
                  width: 280,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2217324B),
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
                          color: Color(0xFF0F3559),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 18),
                      
                      // Ingredient Name Label
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.shoppingListIngredientNameHint,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E4E69),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Ingredient Name Field
                      Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF17324B), fontWeight: FontWeight.w600),
                          textInputAction: TextInputAction.next,
                          onChanged: (value) {
                            setState(() {});
                            _loadSuggestions(value);
                          },
                          onSubmitted: (_) {
                            _amountFocusNode.requestFocus();
                          },
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFDAE6F5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFDAE6F5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF8BB3D6), width: 1.5),
                            ),
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
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE4EBF2)),
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 120),
                            child: Material(
                              color: Colors.transparent,
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _suggestions.length,
                                separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFE4EBF2)),
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
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF17324B), fontWeight: FontWeight.w600),
                                      ),
                                      onTap: () {
                                        _debounce?.cancel();
                                        final hasIcon = suggestion.icon.trim().isNotEmpty;
                                        final textValue = hasIcon
                                            ? '${suggestion.icon.trim()} ${suggestion.name}'
                                            : suggestion.name;
                                        _nameController.text = textValue;
                                        _nameController.selection = TextSelection.collapsed(
                                          offset: textValue.length,
                                        );
                                        setState(() {
                                          _suggestions = const [];
                                        });
                                        _amountFocusNode.requestFocus();
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 14),

                      // Ingredient Amount Label
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          l10n.recipeIngredientAmountHint,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E4E69),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Ingredient Amount Field
                      Material(
                        color: Colors.transparent,
                        child: TextField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF17324B), fontWeight: FontWeight.w600),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: l10n.shoppingListIngredientAmountHint,
                            hintStyle: const TextStyle(color: Color(0xFF8BB3D6), fontSize: 13, fontWeight: FontWeight.normal),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFDAE6F5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFFDAE6F5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF8BB3D6), width: 1.5),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _nameController.text.trim().isEmpty || _submitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F5D7E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                              : Text(
                                  widget.confirmLabel,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
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
