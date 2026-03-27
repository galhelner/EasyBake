import 'package:flutter/material.dart';

class RecipeCreateInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Color primaryColor;
  final Color hintColor;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  const RecipeCreateInputField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.primaryColor,
    required this.hintColor,
    this.hasError = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(color: primaryColor, fontSize: 20),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 18,
            height: 1,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
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
