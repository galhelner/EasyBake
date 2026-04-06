import 'package:flutter/material.dart';

import '../widgets/auth_input_field.dart';

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
  final Future<bool> Function(String email) onCheckEmailExists;
  final Future<void> Function() onEmailExists;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _kButtonBlue = Color(0xFF8BB3D6);
  static const _kActionBlue = Color(0xFF1B75DD);
  static const _kPrimaryText = Color(0xFF1E2C44);
  static const _kThemeBackground = Color(0xFFF6FAFF);
  static const _kProgressTrack = Color(0xFFE1EBF6);

  late final PageController _pageController;
  int _currentPage = 0;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFormKey = GlobalKey<FormState>();
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _showNameStepErrorLogo = false;

  void _resetNameStepErrorVisuals() {
    if (_showNameStepErrorLogo) {
      setState(() => _showNameStepErrorLogo = false);
      _nameFormKey.currentState?.validate();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Please enter your email';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> _proceedToNextStep() async {
    if (_isLoading) {
      return;
    }

    if (_currentPage == 0) {
      final nameValidationError = _validateName(_nameController.text);
      if (nameValidationError != null) {
        setState(() => _showNameStepErrorLogo = true);
        _nameFormKey.currentState?.validate();
        return;
      }

      if (_showNameStepErrorLogo) {
        setState(() => _showNameStepErrorLogo = false);
      }
    }

    final isCurrentStepValid = switch (_currentPage) {
      0 => true,
      1 => _emailFormKey.currentState?.validate() ?? false,
      _ => true,
    };

    if (!isCurrentStepValid || _currentPage >= 2) {
      return;
    }

    if (_currentPage == 1) {
      setState(() => _isLoading = true);

      try {
        final exists = await widget.onCheckEmailExists(
          _emailController.text.trim(),
        );

        if (exists) {
          if (mounted) {
            await widget.onEmailExists();
          }
          return;
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _goToPreviousStep() async {
    if (_isLoading || _currentPage == 0) {
      return;
    }

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleRegister() async {
    if (_isLoading) {
      return;
    }

    final hasNameError = _validateName(_nameController.text) != null;
    if (hasNameError) {
      setState(() => _showNameStepErrorLogo = true);
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _nameFormKey.currentState?.validate();
      return;
    }

    final hasEmailError = _validateEmail(_emailController.text) != null;
    if (hasEmailError) {
      await _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _emailFormKey.currentState?.validate();
      return;
    }

    final isPasswordValid = _passwordFormKey.currentState?.validate() ?? false;
    if (!isPasswordValid) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        'Step ${_currentPage + 1} of 3',
                        key: ValueKey<int>(_currentPage),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _kPrimaryText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProgressBar(),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                  },
                  children: [
                    _buildIdentityStep(),
                    _buildCommunicationStep(),
                    _buildSecurityStep(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = index <= _currentPage;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            height: 6,
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: isActive ? _kActionBlue : _kProgressTrack,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIdentityStep() {
    return Form(
      key: _nameFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(color: Colors.transparent),
              child: Image.asset(
                _showNameStepErrorLogo
                    ? 'assets/ai_chef_register_error_logo.png'
                    : 'assets/ai_chef_register_logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 18),
          AuthInputField(
            controller: _nameController,
            icon: Icons.person_outline,
            hint: 'Full Name',
            hintFontSize: 14,
            hideErrorText: true,
            validator: (value) {
              if (!_showNameStepErrorLogo) {
                return null;
              }
              return _validateName(value);
            },
            onChanged: (_) => _resetNameStepErrorVisuals(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _proceedToNextStep,
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
              child: const Text(
                'Next',
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
    );
  }

  Widget _buildCommunicationStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kThemeBackground,
              ),
              child: const Icon(
                Icons.email_outlined,
                color: _kActionBlue,
                size: 25,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'What is your email?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: _kPrimaryText,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 18),
          AuthInputField(
            controller: _emailController,
            icon: Icons.email_outlined,
            hint: 'Email Address',
            hintFontSize: 14,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _goToPreviousStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kButtonBlue,
                      side: const BorderSide(color: _kButtonBlue, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _proceedToNextStep,
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
                    child: _isLoading && _currentPage == 1
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Next',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kThemeBackground,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: _kActionBlue,
                size: 25,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Set your password',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: _kPrimaryText,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 18),
          AuthInputField(
            controller: _passwordController,
            icon: Icons.lock_outline,
            hint: 'Password',
            hintFontSize: 14,
            obscureText: _obscurePassword,
            onToggleObscure: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            validator: (value) {
              final password = value ?? '';
              if (password.isEmpty) {
                return 'Please enter a password';
              }
              if (password.length < 8) {
                return 'Min 8 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          AuthInputField(
            controller: _confirmPasswordController,
            icon: Icons.lock_reset_outlined,
            hint: 'Confirm Password',
            hintFontSize: 14,
            obscureText: _obscureConfirmPassword,
            onToggleObscure: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            validator: (value) {
              final confirmPassword = value ?? '';
              if (confirmPassword.isEmpty) {
                return 'Please confirm your password';
              }
              if (confirmPassword != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _goToPreviousStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kButtonBlue,
                      side: const BorderSide(color: _kButtonBlue, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
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
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
