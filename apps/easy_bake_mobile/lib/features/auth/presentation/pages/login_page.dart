import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../recipes/presentation/pages/recipe_list_page.dart';
import '../../data/services/auth_api_service.dart';
import '../providers/auth_notifier.dart';
import '../widgets/auth_input_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _kPageBackground = Color(0xFFF2F7F7);
  static const _kButtonBlue = Color(0xFF8BB3D6);
  static const _kHintText = Color(0xFF706C6C);
  static const _kActionBlue = Color(0xFF1B75DD);
  static const _kLogoAssetPath = 'assets/app_logo_full.png';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegister = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authApiServiceProvider);
      final authState = _isRegister
          ? await authService.register(
              fullName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            )
          : await authService.login(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

      ref
          .read(authNotifierProvider.notifier)
          .setAuth(
            accessToken: authState.accessToken!,
            userId: authState.userId,
            email: authState.email,
          );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const RecipeListPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        await _showAuthErrorDialog(_friendlyAuthErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $label';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 700;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          SizedBox(
                            height: _isRegister
                                ? (isSmallScreen ? 70 : 100)
                                : (isSmallScreen ? 100 : 150),
                            child: Image.asset(
                              _kLogoAssetPath,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isRegister ? "Let's Get Baking!" : 'Welcome Back!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 28 : 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isRegister
                                ? 'Create an account to save\nrecipes and more.'
                                : 'Sign in to keep baking!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: _kHintText,
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_isRegister) ...[
                            AuthInputField(
                              controller: _nameController,
                              icon: Icons.person_outline,
                              hint: 'Full Name',
                              hintFontSize: 16,
                              validator: (value) =>
                                  _validateRequired(value, 'your name'),
                            ),
                            const SizedBox(height: 16),
                          ],
                          AuthInputField(
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hint: 'Email',
                            hintFontSize: 16,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AuthInputField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: 'Password',
                            hintFontSize: 16,
                            obscureText: _obscurePassword,
                            onToggleObscure: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return 'Min 8 characters';
                              }
                              return null;
                            },
                          ),
                          if (_isRegister) ...[
                            const SizedBox(height: 16),
                            AuthInputField(
                              controller: _confirmPasswordController,
                              icon: Icons.lock_reset_outlined,
                              hint: 'Confirm Password',
                              hintFontSize: 16,
                              obscureText: _obscurePassword,
                              onToggleObscure: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ],
                          const Spacer(),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kButtonBlue,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                      _isRegister
                                          ? 'Create an Account'
                                          : 'Sign In',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    setState(() {
                                      _isRegister = !_isRegister;
                                      _formKey.currentState?.reset();
                                    });
                                  },
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                                children: [
                                  TextSpan(
                                    text: _isRegister
                                        ? 'Already have an account? '
                                        : "Don't have an account? ",
                                  ),
                                  TextSpan(
                                    text: _isRegister
                                        ? 'Log In'
                                        : 'Register Now',
                                    style: const TextStyle(
                                      color: _kActionBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _friendlyAuthErrorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Incorrect email or password.';
      }
      if (error.response?.statusCode == 409) return 'Email already in use.';
      return 'Server error. Please try again later.';
    }
    return 'An unexpected error occurred.';
  }

  Future<void> _showAuthErrorDialog(String message) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
