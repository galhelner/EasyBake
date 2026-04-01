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
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            title,
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
        for (var i = 0; i < controllers.length; i++) ...[
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
              const SizedBox(width: 10),
              // Add button
              SizedBox(
                height: 48,
                child: _FieldActionButton(
                  onTap: onAdd,
                  icon: Icons.add_rounded,
                ),
              ),
              // Remove button
              if (controllers.length > 1) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: _FieldActionButton(
                    onTap: () => onRemove(i),
                    icon: Icons.remove_rounded,
                    isRemove: true,
                  ),
                ),
              ],
            ],
          ),
          if (i < controllers.length - 1) const SizedBox(height: 10),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: Color(0xFFFF3B30),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FieldActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final bool isRemove;

  const _FieldActionButton({
    required this.onTap,
    required this.icon,
    this.isRemove = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 48,
          decoration: BoxDecoration(
            color: isRemove
                ? const Color(0xFFFF3B30).withValues(alpha: 0.08)
                : const Color(0xFF8BB3D6).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isRemove
                  ? const Color(0xFFFF3B30).withValues(alpha: 0.2)
                  : const Color(0xFF8BB3D6).withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: isRemove
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFF8BB3D6),
            ),
          ),
        ),
      ),
    );
  }
}
