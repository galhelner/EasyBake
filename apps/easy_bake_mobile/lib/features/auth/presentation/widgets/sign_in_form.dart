import 'package:flutter/material.dart';

import 'auth_input_field.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key, required this.onSubmit});

  final Future<void> Function({required String email, required String password})
  onSubmit;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => _showErrors = true);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onFieldChanged() {
    if (_showErrors) {
      setState(() => _showErrors = false);
      _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(height: 4),
                SizedBox(
                  height: 190,
                  child: Image.asset(
                    'assets/ai_chef_hello.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
                AuthInputField(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  hint: 'Email',
                  hintFontSize: 15,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _onFieldChanged(),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return _showErrors ? 'Enter a valid email' : null;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                AuthInputField(
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  hint: 'Password',
                  hintFontSize: 15,
                  obscureText: _obscurePassword,
                  onToggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  onChanged: (_) => _onFieldChanged(),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return _showErrors ? 'Min 8 characters' : null;
                    }
                    return null;
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style:
                        ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8BB3D6),
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
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
