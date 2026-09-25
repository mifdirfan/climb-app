import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_providers.dart';

/// Screen managing both Sign In and Sign Up flows with dynamic system theme adaptation.
/// Complies with Figma nodes 5315:170 (Sign In) and 5318:215 (Sign Up), strictly
/// consuming design tokens and typography configured in [AppTheme].
class LoginScreen extends ConsumerStatefulWidget {
  final bool initialIsSignUp;

  const LoginScreen({
    super.key,
    this.initialIsSignUp = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  late bool _isSignUp;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _localError;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode(bool isSignUp) {
    if (_isSignUp != isSignUp) {
      setState(() {
        _isSignUp = isSignUp;
        _localError = null;
      });
      _formKey.currentState?.reset();
    }
  }

  void _handleBack() {
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else if (router != null) {
      router.go(AppRoutes.crags);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _localError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      final username = _usernameController.text.trim();
      final success = await ref
          .read(authControllerProvider.notifier)
          .signUp(email, password, username);

      if (success && mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            content: Text(
              'Account created successfully! You can now sign in.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() {
          _isSignUp = false;
        });
      }
    } else {
      final success = await ref
          .read(authControllerProvider.notifier)
          .signIn(email, password);

      if (success && mounted) {
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          if (router.canPop()) {
            router.pop();
          } else {
            router.go(AppRoutes.crags);
          }
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    final forgotEmailController =
        TextEditingController(text: _emailController.text.trim());
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        title: Text(
          'Reset Password',
          style: theme.textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your email address and we will send a password reset link.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: forgotEmailController,
              keyboardType: TextInputType.emailAddress,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: 'climber@crag.com',
                prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'CANCEL',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  content: Text(
                    'Reset instructions sent if email exists.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            },
            child: const Text('SEND LINK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Auth provider status
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    // Active error message
    final activeError = _localError ??
        (authState.hasError ? authState.error.toString() : null);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const ValueKey('back_button'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: _handleBack,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Brand Badge & Icon
                    Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: AppRadius.borderMd,
                          border: Border.all(
                            color: colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.terrain_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Brand Tracker
                    Center(
                      child: Text(
                        'CLIMBMY',
                        style: textTheme.labelSmall?.copyWith(
                          letterSpacing: 3.0,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Headline
                    Text(
                      _isSignUp
                          ? 'Join the ClimbMY community.'
                          : 'Log in to your next ascent.',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      _isSignUp
                          ? 'Create an account to track sends, log topos, and report crag hazards.'
                          : 'Enter your credentials to access topos and log sends.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),

                    // Mode Switcher Segmented Tabs
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildModeTab(
                              title: 'SIGN IN',
                              isSelected: !_isSignUp,
                              theme: theme,
                              onTap: () => _toggleMode(false),
                            ),
                          ),
                          Expanded(
                            child: _buildModeTab(
                              title: 'SIGN UP',
                              isSelected: _isSignUp,
                              theme: theme,
                              onTap: () => _toggleMode(true),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Error Alert Banner (if any)
                    if (activeError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(
                            color: colorScheme.onError.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              size: 18,
                              color: colorScheme.onError,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                activeError,
                                style: textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onError,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _localError = null;
                                });
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: colorScheme.onError,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Username Field (Sign Up only)
                    if (_isSignUp) ...[
                      _buildFieldLabel('USERNAME', theme),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const ValueKey('username_field'),
                        controller: _usernameController,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'climber_adam',
                          prefixIcon: Icon(
                            Icons.alternate_email_rounded,
                            size: 20,
                            color: textTheme.bodyMedium?.color,
                          ),
                        ),
                        validator: (val) {
                          if (!_isSignUp) return null;
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter a username';
                          }
                          if (val.trim().length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Email Address Field
                    _buildFieldLabel('EMAIL ADDRESS', theme),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const ValueKey('email_field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'climber@crag.com',
                        prefixIcon: Icon(
                          Icons.mail_outline_rounded,
                          size: 20,
                          color: textTheme.bodyMedium?.color,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter your email address';
                        }
                        final emailRegex =
                            RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(val.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Password Field
                    _buildFieldLabel('PASSWORD', theme),
                    const SizedBox(height: 6),
                    TextFormField(
                      key: const ValueKey('password_field'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            _isSignUp ? 'At least 6 characters' : '••••••••',
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: textTheme.bodyMedium?.color,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: textTheme.bodyMedium?.color,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    // Forgot Password link (Sign In only)
                    if (!_isSignUp) ...[
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 14),

                    // Confirm Password Field (Sign Up only)
                    if (_isSignUp) ...[
                      _buildFieldLabel('CONFIRM PASSWORD', theme),
                      const SizedBox(height: 6),
                      TextFormField(
                        key: const ValueKey('confirm_password_field'),
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Re-enter your password',
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: textTheme.bodyMedium?.color,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: textTheme.bodyMedium?.color,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (!_isSignUp) return null;
                          if (val == null || val.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (val != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Submit Primary Button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        key: const ValueKey('submit_auth_button'),
                        onPressed: isLoading ? null : _handleSubmit,
                        child: isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                                style: textTheme.labelLarge,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // "OR CONTINUE WITH" Divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.dividerTheme.color ??
                                colorScheme.outlineVariant,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'OR CONTINUE WITH',
                            style: textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.0,
                              color: textTheme.bodySmall?.color,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.dividerTheme.color ??
                                colorScheme.outlineVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Social Auth Buttons (Google & Apple)
                    _buildSocialButton(
                      label: _isSignUp
                          ? 'Sign up with Google'
                          : 'Sign in with Google',
                      icon: _buildGoogleIcon(theme),
                      theme: theme,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            content: Text(
                              'Google authentication is coming soon.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),

                    _buildSocialButton(
                      label: _isSignUp
                          ? 'Sign up with Apple'
                          : 'Sign in with Apple',
                      icon: Icon(
                        Icons.apple,
                        size: 22,
                        color: colorScheme.onSurface,
                      ),
                      theme: theme,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            content: Text(
                              'Apple authentication is coming soon.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Footer Switcher
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _isSignUp
                                ? 'Already have an account? '
                                : "Don't have an account? ",
                            style: textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            key: const ValueKey('footer_mode_switch'),
                            onTap: () => _toggleMode(!_isSignUp),
                            child: Text(
                              _isSignUp ? 'Sign In' : 'Sign Up',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, ThemeData theme) {
    return Text(
      label,
      style: theme.textTheme.labelSmall?.copyWith(
        letterSpacing: 0.8,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final activeBg = theme.colorScheme.primary;
    final activeFg = theme.colorScheme.onPrimary;
    final inactiveFg = theme.textTheme.bodyMedium?.color;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderXs,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: AppRadius.borderXs,
        ),
        child: Center(
          child: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? activeFg : inactiveFg,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required String label,
    required Widget icon,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderSm,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.borderSm,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon(ThemeData theme) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: Text(
        'G',
        style: theme.textTheme.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF4285F4),
        ),
      ),
    );
  }
}
