import 'package:flutter/material.dart';

class RecipeCreateInputField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Color primaryColor;
  final Color hintColor;
  final bool hasError;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;

  const RecipeCreateInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.primaryColor,
    required this.hintColor,
    this.hasError = false,
    this.prefixIcon,
    this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  State<RecipeCreateInputField> createState() => _RecipeCreateInputFieldState();
}

class _RecipeCreateInputFieldState extends State<RecipeCreateInputField> {
  @override
  Widget build(BuildContext context) {
    final isMultiline = widget.maxLines > 1;

    return ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: 48,
          maxHeight: isMultiline ? 140 : 48,
        ),
        child: TextFormField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          keyboardType: isMultiline
              ? TextInputType.multiline
              : TextInputType.text,
          textInputAction: isMultiline
              ? TextInputAction.newline
              : TextInputAction.next,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          style: TextStyle(
            color: widget.primaryColor,
            fontSize: isMultiline ? 15 : 16,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
          textAlignVertical: TextAlignVertical.top,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: widget.hintColor.withValues(alpha: 0.5),
              fontSize: isMultiline ? 15 : 16,
              height: 1.4,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: widget.prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 14, right: 8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Center(child: widget.prefixIcon),
                    ),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isMultiline ? 12 : 12,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.hasError
                    ? const Color(0xFFFF3B30)
                    : const Color(0xFFE0E8ED),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.hasError
                    ? const Color(0xFFFF3B30)
                    : const Color(0xFFE0E8ED),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: widget.hasError
                    ? const Color(0xFFFF3B30)
                    : const Color(0xFF8BB3D6),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFFF3B30),
                width: 2,
              ),
            ),
          ),
        ),
      );
  }
}
