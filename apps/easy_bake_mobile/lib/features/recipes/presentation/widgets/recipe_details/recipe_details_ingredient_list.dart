import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import 'recipe_scale_toggle.dart';

class RecipeDetailsIngredientList extends StatefulWidget {
  const RecipeDetailsIngredientList({
    super.key,
    required this.items,
    required this.scale,
    required this.onScaleChanged,

    Map<String, String>? iconsByName,
    Map<String, String>? amountsByName,
  }) : iconsByName = iconsByName ?? const {},
       amountsByName = amountsByName ?? const {};

  final List<String> items;
  final Map<String, String> iconsByName;
  final Map<String, String> amountsByName;
  final double scale;
  final ValueChanged<double> onScaleChanged;

  @override
  State<RecipeDetailsIngredientList> createState() =>
      _RecipeDetailsIngredientListState();
}

class _RecipeDetailsIngredientListState
    extends State<RecipeDetailsIngredientList> {
  static const Color _paperBackground = Color(0xFFFBF7EE);
  static const Color _paperBorder = Color(0xFFE6DDCD);
  static const Color _paperDivider = Color(0xFFE9E1D2);
  static const Color _controlAccent = Color(0xFF2E4E69);

  static final RegExp _mixedFractionRegExp = RegExp(
    r'^\s*(\d+)\s+(\d+)\s*/\s*(\d+)(.*)',
  );

  static final RegExp _fractionRegExp = RegExp(r'^\s*(\d+)\s*/\s*(\d+)(.*)');
  static final RegExp _numberRegExp = RegExp(r'^\s*([+-]?\d+(?:\.\d+)?)(.*)');
  late List<bool> _checkedItems;

  @override
  void initState() {
    super.initState();
    _checkedItems = List<bool>.filled(widget.items.length, false);
  }

  @override
  void didUpdateWidget(covariant RecipeDetailsIngredientList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasRecipeChanged =
        oldWidget.items.length != widget.items.length ||
        !_isSameIngredients(oldWidget.items, widget.items);
    if (hasRecipeChanged) {
      _checkedItems = List<bool>.filled(widget.items.length, false);
    }
  }

  bool _isSameIngredients(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  bool _isPresetScale(double scale) {
    return scale == 1 || scale == 2 || scale == 3;
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    var text = value.toStringAsFixed(2);

    while (text.contains('.') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }

    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  String _scaleAmount(String amount) {
    if (widget.scale == 1) {
      return amount.trim();
    }

    final normalized = amount.trim();
    if (normalized.isEmpty) {
      return normalized;
    }

    final mixedMatch = _mixedFractionRegExp.firstMatch(normalized);

    if (mixedMatch != null) {
      final whole = int.tryParse(mixedMatch.group(1) ?? '');
      final numerator = int.tryParse(mixedMatch.group(2) ?? '');
      final denominator = int.tryParse(mixedMatch.group(3) ?? '');

      if (whole != null &&
          numerator != null &&
          denominator != null &&
          denominator != 0) {
        final base = whole + (numerator / denominator);
        final suffix = mixedMatch.group(4) ?? '';
        return '${_formatNumber(base * widget.scale)}$suffix';
      }
    }

    final fractionMatch = _fractionRegExp.firstMatch(normalized);

    if (fractionMatch != null) {
      final numerator = int.tryParse(fractionMatch.group(1) ?? '');
      final denominator = int.tryParse(fractionMatch.group(2) ?? '');

      if (numerator != null && denominator != null && denominator != 0) {
        final base = numerator / denominator;
        final suffix = fractionMatch.group(3) ?? '';
        return '${_formatNumber(base * widget.scale)}$suffix';
      }
    }

    final numberMatch = _numberRegExp.firstMatch(normalized);

    if (numberMatch != null) {
      final number = double.tryParse(numberMatch.group(1) ?? '');
      if (number != null) {
        final suffix = numberMatch.group(2) ?? '';
        return '${_formatNumber(number * widget.scale)}$suffix';
      }
    }
    return normalized;
  }

  Future<void> _showCustomScaleDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: _isPresetScale(widget.scale) ? '' : _formatNumber(widget.scale),
    );
    final customScale = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.customScaleTitle),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: l10n.enterDesiredScaleHint,
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                final parsed = double.tryParse(controller.text.trim());
                if (parsed == null || parsed <= 0) {
                  return;
                }
                Navigator.of(dialogContext).pop(parsed);
              },
              child: Text(l10n.applyButtonLabel),
            ),
          ],
        );
      },
    );

    if (!mounted || customScale == null) {
      return;
    }

    widget.onScaleChanged(customScale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.items.isEmpty) {
      return Text(
        l10n.noIngredientsAvailableMessage,
        style: const TextStyle(color: Color(0xFF2B3D5A), fontSize: 16),
      );
    }

    final isPresetScale = _isPresetScale(widget.scale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _paperBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _paperBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.recipeScalesTitle,
                style: TextStyle(
                  color: Color(0xFF6B7F92),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RecipeScaleToggle(
                    currentScale: widget.scale,
                    onScaleChanged: widget.onScaleChanged,
                  ),
                  const SizedBox(width: 12),
                  if (isPresetScale)
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: _showCustomScaleDialog,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: _paperBorder,
                            width: 1.2,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: Colors.white.withValues(alpha: 0.65),
                        ),
                        icon: const Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: _controlAccent,
                        ),
                        label: Text(
                          l10n.customScaleButtonLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _controlAccent,
                          ),
                        ),
                      ),
                    )
                  else
                    _CustomScaleChip(
                      scale: widget.scale,
                      onTap: _showCustomScaleDialog,
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _paperBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < widget.items.length; i++)
                Column(
                  children: [
                    _IngredientTile(
                      text: widget.items[i],
                      amount: widget.amountsByName[widget.items[i]] == null
                          ? null
                          : _scaleAmount(
                              widget.amountsByName[widget.items[i]]!,
                            ),
                      icon: widget.iconsByName[widget.items[i]],
                      checked: _checkedItems[i],
                      onChanged: (checked) {
                        setState(() {
                          _checkedItems[i] = checked;
                        });
                      },
                    ),
                    if (i != widget.items.length - 1)
                      const Padding(
                        padding: EdgeInsets.only(left: 42),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: _paperDivider,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CustomScaleChip extends StatelessWidget {
  const _CustomScaleChip({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    var text = value.toStringAsFixed(2);

    while (text.contains('.') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }

    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF4FB),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF8CB7D8), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E4E69).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: Color(0xFF2E4E69),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_formatNumber(scale)}x',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E4E69),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    required this.text,
    this.amount,
    this.icon,
    required this.checked,
    required this.onChanged,
  });

  final String text;
  final String? amount;
  final String? icon;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!checked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
          decoration: BoxDecoration(
            color: checked ? const Color(0xFFEAF4EC) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: checked,
                  onChanged: (value) => onChanged(value ?? false),
                  side: BorderSide(
                    color: checked
                        ? const Color(0xFF5F8E68)
                        : const Color(0xFF2B3D5A),
                  ),
                  activeColor: const Color(0xFF5F8E68),
                  checkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (icon != null && icon!.isNotEmpty) ...[
                Text(icon!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: checked
                        ? const Color(0xFF5D6F69)
                        : const Color(0xFF2B3D5A),
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    decoration: checked
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: const Color(0xFF5D6F69),
                    decorationThickness: 2,
                  ),
                ),
              ),
              if (amount != null && amount!.trim().isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: checked
                        ? const Color(0xFF5F8E68).withValues(alpha: 0.12)
                        : const Color(0xFF2E4E69).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    amount!.trim(),
                    style: TextStyle(
                      color: checked
                          ? const Color(0xFF4E6F55)
                          : const Color(0xFF2E4E69),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
