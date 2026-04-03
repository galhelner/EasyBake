import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/auth_api_service.dart';
import '../providers/auth_notifier.dart';
import '../widgets/auth_mode_toggle.dart';
import '../widgets/register_form.dart';
import '../widgets/sign_in_form.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  static const _kPageBackground = Color(0xFFF2F7F7);
  static const _kButtonBlue = Color(0xFF8BB3D6);
  static const _kActionBlue = Color(0xFF1B75DD);
  static const _kPrimaryText = Color(0xFF1E2C44);
  static const _kCardBackground = Color(0xFFF8FCFC);
  static const _kLogoAssetPath = 'assets/app_logo_full.png';

  bool _isRegister = false;

  Future<void> _handleSignIn({
    required String email,
    required String password,
  }) async {
    try {
      final authService = ref.read(authApiServiceProvider);
      final authState = await authService.login(
        email: email,
        password: password,
      );

      ref
          .read(authNotifierProvider.notifier)
          .setAuth(
            accessToken: authState.accessToken!,
            userId: authState.userId,
            email: authState.email,
            displayName: authState.displayName,
          );
    } catch (error) {
      if (mounted) {
        await _showAuthErrorDialog(_friendlyAuthErrorMessage(error));
      }
    }
  }

  Future<void> _handleRegister({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final authService = ref.read(authApiServiceProvider);
      final authState = await authService.register(
        fullName: fullName,
        email: email,
        password: password,
      );

      ref
          .read(authNotifierProvider.notifier)
          .setAuth(
            accessToken: authState.accessToken!,
            userId: authState.userId,
            email: authState.email,
            displayName: authState.displayName,
          );
    } catch (error) {
      if (mounted) {
        await _showAuthErrorDialog(_friendlyAuthErrorMessage(error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: _kPageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 700;
            final logoHeight = isSmallScreen ? 64.0 : 82.0;
            final formAreaHeight = isSmallScreen ? 330.0 : 362.0;

            return Stack(
              children: [
                Align(
                  alignment: const Alignment(-1.2, -1.1),
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kButtonBlue.withValues(alpha: 0.20),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(1.2, -0.75),
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kActionBlue.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(1.25, 1.15),
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _kButtonBlue.withValues(alpha: 0.18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 12,
                          bottom: keyboardInset + 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 430,
                                ),
                                padding: EdgeInsets.fromLTRB(
                                  18,
                                  isSmallScreen ? 14 : 18,
                                  18,
                                  16,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [_kCardBackground, Colors.white],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    width: 1.1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _kActionBlue.withValues(
                                        alpha: 0.10,
                                      ),
                                      blurRadius: 32,
                                      offset: const Offset(0, 16),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: logoHeight,
                                      child: Image.asset(
                                        _kLogoAssetPath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 8 : 12),
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _kButtonBlue.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      child: AuthModeToggle(
                                        isRegister: _isRegister,
                                        onSignInTap: () {
                                          if (_isRegister) {
                                            setState(() => _isRegister = false);
                                          }
                                        },
                                        onRegisterTap: () {
                                          if (!_isRegister) {
                                            setState(() => _isRegister = true);
                                          }
                                        },
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 12 : 14),
                                    Text(
                                      _isRegister
                                          ? "Let's Get Baking!"
                                          : 'Welcome Back!',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.headlineMedium
                                          ?.copyWith(
                                            fontSize: isSmallScreen ? 24 : 29,
                                            fontWeight: FontWeight.w800,
                                            color: _kPrimaryText,
                                            letterSpacing: 0.2,
                                          ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 18 : 24),
                                    SizedBox(
                                      height: formAreaHeight,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 220,
                                        ),
                                        switchInCurve: Curves.easeOut,
                                        switchOutCurve: Curves.easeIn,
                                        layoutBuilder:
                                            (currentChild, previousChildren) {
                                              return Stack(
                                                alignment: Alignment.topCenter,
                                                children: [
                                                  ...previousChildren,
                                                  currentChild ??
                                                      const SizedBox.shrink(),
                                                ],
                                              );
                                            },
                                        child: _isRegister
                                            ? RegisterForm(
                                                key: const ValueKey(
                                                  'register_form',
                                                ),
                                                onSubmit: _handleRegister,
                                              )
                                            : SignInForm(
                                                key: const ValueKey(
                                                  'sign_in_form',
                                                ),
                                                onSubmit: _handleSignIn,
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _kActionBlue.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kButtonBlue.withValues(alpha: 0.22),
                ),
                child: const Icon(
                  Icons.sentiment_dissatisfied_rounded,
                  color: _kActionBlue,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Oops! Something went wrong',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kPrimaryText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Color(0xFF4C5B72),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kButtonBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
