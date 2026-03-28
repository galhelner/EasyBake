import 'package:flutter/material.dart';

import 'recipe_create_input_field.dart';

class RecipeCreateDynamicSection extends StatelessWidget {
  final String title;
  final String fieldHint;
  final List<TextEditingController> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final Color primaryColor;
  final Color hintColor;
  final bool hasError;
  final String? errorText;
  final ValueChanged<String>? onFieldChanged;
  final int minLines;
  final int maxLines;

  const RecipeCreateDynamicSection({
    super.key,
    required this.title,
    required this.fieldHint,
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
    required this.primaryColor,
    required this.hintColor,
    this.hasError = false,
    this.errorText,
    this.onFieldChanged,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: primaryColor,
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        for (var i = 0; i < controllers.length; i++) ...[
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RecipeCreateInputField(
                  controller: controllers[i],
                  hintText: '$fieldHint #${i + 1}',
                  primaryColor: primaryColor,
                  hintColor: hintColor,
                  hasError: hasError,
                  onChanged: onFieldChanged,
                  minLines: minLines,
                  maxLines: maxLines,
                ),
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _FieldActionButton(
                  onTap: onAdd,
                  primaryColor: primaryColor,
                  icon: Icons.add,
                ),
              ),
              if (controllers.length > 1) ...[
                const SizedBox(width: 8),
                _FieldActionButton(
                  onTap: () => onRemove(i),
                  primaryColor: primaryColor,
                  icon: Icons.remove,
                ),
              ],
            ],
          ),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
      ],
    );
  }
}

class _FieldActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color primaryColor;
  final IconData icon;

  const _FieldActionButton({
    required this.onTap,
    required this.primaryColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor, width: 2.5),
        ),
        child: Icon(icon, size: 22, color: primaryColor),
      ),
    );
  }
}
