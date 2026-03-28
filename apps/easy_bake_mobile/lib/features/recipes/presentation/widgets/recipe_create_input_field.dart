import 'package:flutter/material.dart';

class RecipeCreateInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color primaryColor;
  final Color hintColor;
  final bool hasError;
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
    this.onChanged,
    this.minLines = 1,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiline = maxLines > 1;

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 45,
        maxHeight: isMultiline ? 130 : 45,
      ),
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: isMultiline
            ? TextInputType.multiline
            : TextInputType.text,
        textInputAction: isMultiline
            ? TextInputAction.newline
            : TextInputAction.next,
        minLines: minLines,
        maxLines: maxLines,
        style: TextStyle(
          color: primaryColor,
          fontSize: isMultiline ? 16 : 20,
          height: 1.25,
        ),
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: isMultiline ? 15 : 18,
            height: 1.2,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: isMultiline ? 12 : 10,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: hasError ? Colors.red : primaryColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: hasError ? Colors.red : primaryColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(
              color: hasError ? Colors.red : primaryColor,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
