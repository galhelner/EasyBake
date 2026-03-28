import 'package:flutter/material.dart';

class RecipeDetailsIngredientList extends StatefulWidget {
  const RecipeDetailsIngredientList({super.key, required this.items});

  final List<String> items;

  @override
  State<RecipeDetailsIngredientList> createState() =>
      _RecipeDetailsIngredientListState();
}

class _RecipeDetailsIngredientListState
    extends State<RecipeDetailsIngredientList> {
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

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Text(
        'No ingredients available.',
        style: TextStyle(color: Color(0xFF2B3D5A), fontSize: 16),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ingredients Checklist',
          style: TextStyle(
            color: Color(0xFF243954),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < widget.items.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == widget.items.length - 1 ? 0 : 12,
            ),
            child: _IngredientTile(
              text: widget.items[i],
              checked: _checkedItems[i],
              onChanged: (checked) {
                setState(() {
                  _checkedItems[i] = checked;
                });
              },
            ),
          ),
      ],
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({
    required this.text,
    required this.checked,
    required this.onChanged,
  });

  final String text;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(!checked),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: checked ? const Color(0xFFEAF4EC) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: checked
                  ? const Color(0xFF87B08F)
                  : const Color(0xFFCBD7E6),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 30,
                height: 30,
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
              const SizedBox(width: 12),
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
            ],
          ),
        ),
      ),
    );
  }
}
