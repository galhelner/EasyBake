import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../home/presentation/pages/home_tabs_page.dart';
import '../../data/services/auth_api_service.dart';
import '../providers/auth_notifier.dart';
import '../widgets/auth_mode_toggle.dart';
import 'register_page.dart';
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

  final PageController _authModePageController = PageController(initialPage: 0);
  int _authModeIndex = 0;

  @override
  void dispose() {
    _authModePageController.dispose();
    super.dispose();
  }

  Future<void> _goToSignInTab() async {
    if (_authModeIndex == 0) {
      return;
    }

    await _authModePageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goToRegisterTab() async {
    if (_authModeIndex == 1) {
      return;
    }

    await _authModePageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

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
        await _showAuthErrorDialog(_authErrorDialogData(error));
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

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeTabsPage()),
          (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        await _showAuthErrorDialog(
          _authErrorDialogData(error, isRegister: true),
        );
      }
    }
  }

  Future<bool> _checkEmailExists(String email) async {
    try {
      final authService = ref.read(authApiServiceProvider);
      return await authService.emailExists(email: email);
    } catch (error) {
      if (mounted) {
        await _showAuthErrorDialog(_authErrorDialogData(error));
      }
      return true;
    }
  }

  Future<void> _showEmailExistsDialog() {
    return _showAuthErrorDialog(
      const _AuthErrorDialogData(
        title: 'Email already exists',
        message: 'A user with this email is already registered.',
        icon: Icons.email_outlined,
        accentColor: Color(0xFFD64545),
        iconBackgroundColor: Color(0xFFFCE8E8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: _kPageBackground,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 700;
            final logoHeight = isSmallScreen ? 64.0 : 82.0;
            final baseFormAreaHeight = isSmallScreen ? 350.0 : 382.0;
            final sharedExtraHeight = isSmallScreen ? 56.0 : 64.0;
            final keyboardExtraHeight = keyboardInset > 0 ? 24.0 : 0.0;
            final formAreaHeight =
              baseFormAreaHeight +
              sharedExtraHeight +
              keyboardExtraHeight;

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
                                        isRegister: _authModeIndex == 1,
                                        onSignInTap: _goToSignInTab,
                                        onRegisterTap: _goToRegisterTab,
                                      ),
                                    ),
                                    SizedBox(height: isSmallScreen ? 12 : 14),
                                    SizedBox(
                                      height: formAreaHeight,
                                      child: PageView(
                                        controller: _authModePageController,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        onPageChanged: (page) {
                                          setState(() => _authModeIndex = page);
                                        },
                                        children: [
                                          SignInForm(
                                            key: const ValueKey('sign_in_form'),
                                            onSubmit: _handleSignIn,
                                          ),
                                          RegisterPage(
                                            key: const ValueKey(
                                              'register_page',
                                            ),
                                            onSubmit: _handleRegister,
                                            onCheckEmailExists:
                                                _checkEmailExists,
                                            onEmailExists:
                                                _showEmailExistsDialog,
                                          ),
                                        ],
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

  _AuthErrorDialogData _authErrorDialogData(
    Object error, {
    bool isRegister = false,
  }) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return const _AuthErrorDialogData(
          title: 'Wrong credentials',
          message: 'The email or password is incorrect. Please try again.',
          icon: Icons.lock_outline_rounded,
          accentColor: _kActionBlue,
          iconBackgroundColor: Color(0xFFE6F0FA),
        );
      }
      if (isRegister && _isEmailAlreadyRegisteredError(error)) {
        return const _AuthErrorDialogData(
          title: 'Email already exists',
          message: 'A user with this email is already registered.',
          icon: Icons.email_outlined,
          accentColor: Color(0xFFD64545),
          iconBackgroundColor: Color(0xFFFCE8E8),
        );
      }

      return const _AuthErrorDialogData(
        title: 'Oops! Something went wrong',
        message: 'Please try again in a moment.',
        icon: Icons.sentiment_dissatisfied_rounded,
        accentColor: _kActionBlue,
        iconBackgroundColor: Color(0xFFE6F0FA),
      );
    }

    return const _AuthErrorDialogData(
      title: 'Oops! Something went wrong',
      message: 'An unexpected error occurred. Please try again.',
      icon: Icons.sentiment_dissatisfied_rounded,
      accentColor: _kActionBlue,
      iconBackgroundColor: Color(0xFFE6F0FA),
    );
  }

  bool _isEmailAlreadyRegisteredError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode != 400 && statusCode != 409) {
      return false;
    }

    final errorText = _extractErrorText(error.response?.data).toLowerCase();
    return errorText.contains('email already registered') ||
        errorText.contains('email already exists') ||
        errorText.contains('already registered') ||
        errorText.contains('already exists') ||
        errorText.contains('email in use') ||
        errorText.contains('email exists');
  }

  String _extractErrorText(Object? responseData) {
    if (responseData is Map<String, dynamic>) {
      final values = <Object?>[
        responseData['error'],
        responseData['message'],
        responseData['detail'],
        responseData['details'],
      ];

      return values.whereType<String>().join(' ');
    }

    return responseData?.toString() ?? '';
  }

  Future<void> _showAuthErrorDialog(_AuthErrorDialogData data) {
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
                  color: data.iconBackgroundColor,
                ),
                child: Icon(data.icon, color: data.accentColor, size: 30),
              ),
              const SizedBox(height: 14),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _kPrimaryText,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                data.message,
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

class _AuthErrorDialogData {
  const _AuthErrorDialogData({
    required this.title,
    required this.message,
    required this.icon,
    required this.accentColor,
    required this.iconBackgroundColor,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accentColor;
  final Color iconBackgroundColor;
}
