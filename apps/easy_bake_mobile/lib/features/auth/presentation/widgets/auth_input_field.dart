import 'package:flutter/material.dart';

class AuthInputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final double hintFontSize;
  final bool obscureText;
  final VoidCallback? onToggleObscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool hideErrorText;

  const AuthInputField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    required this.hintFontSize,
    this.obscureText = false,
    this.onToggleObscure,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.hideErrorText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF304466),
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: hintFontSize,
          color: const Color(0xFF706C6C),
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF304466), size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF706C6C),
                ),
                onPressed: onToggleObscure,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        errorStyle: hideErrorText
            ? const TextStyle(
                fontSize: 0,
                height: 0,
                color: Colors.transparent,
              )
            : null,
        errorMaxLines: 1,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF304466), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF304466), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }
}
