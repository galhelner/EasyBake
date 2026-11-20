import 'package:flutter/material.dart';
import 'package:easy_bake_mobile/l10n/app_localizations.dart';

import '../widgets/auth_input_field.dart';
import '../widgets/register_form_header.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onSubmit,
    required this.onCheckEmailExists,
    required this.onEmailExists,
  });

  final Future<void> Function({
    required String fullName,
    required String email,
    required String password,
  })
  onSubmit;
  final Future<bool?> Function(String email) onCheckEmailExists;
  final Future<void> Function() onEmailExists;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _kButtonBlue = Color(0xFF8BB3D6);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (_showErrors) {
      setState(() => _showErrors = false);
      _formKey.currentState?.validate();
    }
  }

  String? _validateName(String? value, AppLocalizations l10n) {
    if (!_showErrors) return null;
    if (value == null || value.trim().isEmpty) {
      return l10n.registerErrorNameRequired;
    }
    if (value.trim().length < 2) {
      return l10n.registerErrorNameTooShort;
    }
    return null;
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    if (!_showErrors) return null;
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return l10n.registerErrorEmailRequired;
    }
    if (!email.contains('@') || !email.contains('.')) {
      return l10n.registerErrorEmailInvalid;
    }
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    if (!_showErrors) return null;
    final password = value ?? '';
    if (password.isEmpty) {
      return l10n.registerErrorPasswordRequired;
    }
    if (password.length < 8) {
      return l10n.registerErrorPasswordMinLength;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value, AppLocalizations l10n) {
    if (!_showErrors) return null;
    final confirmPassword = value ?? '';
    if (confirmPassword.isEmpty) {
      return l10n.registerErrorConfirmPasswordRequired;
    }
    if (confirmPassword != _passwordController.text) {
      return l10n.registerErrorPasswordMismatch;
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (_isLoading) {
      return;
    }

    setState(() => _showErrors = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final exists = await widget.onCheckEmailExists(email);

      if (exists == null) {
        return;
      }

      if (exists) {
        if (mounted) {
          await widget.onEmailExists();
        }
        return;
      }

      await widget.onSubmit(
        fullName: _nameController.text.trim(),
        email: email,
        password: _passwordController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  const RegisterFormHeader(),
                  const SizedBox(height: 16),
                  AuthInputField(
                    controller: _nameController,
                    icon: Icons.person_outline,
                    hint: l10n.fullNameHint,
                    hintFontSize: 15,
                    validator: (value) => _validateName(value, l10n),
                    onChanged: (_) => _onFieldChanged(),
                  ),
                  const SizedBox(height: 12),
                  AuthInputField(
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: l10n.emailAddressHint,
                    hintFontSize: 15,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => _validateEmail(value, l10n),
                    onChanged: (_) => _onFieldChanged(),
                  ),
                  const SizedBox(height: 12),
                  AuthInputField(
                    controller: _passwordController,
                    icon: Icons.lock_outline,
                    hint: l10n.passwordHint,
                    hintFontSize: 15,
                    obscureText: _obscurePassword,
                    onToggleObscure: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                    validator: (value) => _validatePassword(value, l10n),
                    onChanged: (_) => _onFieldChanged(),
                  ),
                  const SizedBox(height: 12),
                  AuthInputField(
                    controller: _confirmPasswordController,
                    icon: Icons.lock_reset_outlined,
                    hint: l10n.confirmPasswordHint,
                    hintFontSize: 15,
                    obscureText: _obscureConfirmPassword,
                    onToggleObscure: () {
                      setState(
                        () => _obscureConfirmPassword =
                            !_obscureConfirmPassword,
                      );
                    },
                    validator: (value) => _validateConfirmPassword(value, l10n),
                    onChanged: (_) => _onFieldChanged(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
              style:
                  ElevatedButton.styleFrom(
                    backgroundColor: _kButtonBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ).copyWith(
                    overlayColor: WidgetStatePropertyAll(
                      Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      l10n.registerLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
