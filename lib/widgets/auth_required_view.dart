import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';

/// A full-screen or centered view displayed when a feature requires user authentication.
/// Replaces transient bottom snackbar prompts with a focused screen and centered sign-in action.
class AuthRequiredView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? categoryLabel;
  final IconData icon;
  final String redirectPath;
  final VoidCallback? onBack;
  final bool showAppBar;

  const AuthRequiredView({
    super.key,
    this.title = 'Sign In Required',
    this.subtitle = 'Please sign in to log your climbing sends, ticks, and personal gym sessions.',
    this.categoryLabel = 'SIGN IN REQUIRED',
    this.icon = Icons.lock_outline_rounded,
    this.redirectPath = AppRoutes.ticks,
    this.onBack,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = showAppBar || onBack != null || context.canPop();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: canGoBack
          ? AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: context.palette.textPrimary),
                onPressed: onBack ?? () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.crags);
                  }
                },
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Lock Icon Container
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.palette.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.palette.accent.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: context.palette.accent,
                  ),
                ),
                if (categoryLabel != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    categoryLabel!,
                    style: context.textStyles.labelLarge.copyWith(
                      color: context.palette.accent,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  title,
                  style: context.textStyles.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.palette.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: context.textStyles.bodyMedium.copyWith(
                      color: context.palette.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 32),

                // Primary Sign In Button in the middle
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('auth_view_sign_in_button'),
                    onPressed: () {
                      debugPrint('--> [AUTH:UI] Sign-in tapped (redirect=$redirectPath)');
                      context.push(
                        '${AppRoutes.login}?redirect=${Uri.encodeComponent(redirectPath)}',
                      );
                    },
                    child: const Text('SIGN IN'),
                  ),
                ),
                const SizedBox(height: 14),

                // Secondary Sign Up Link
                TextButton(
                  key: const Key('auth_view_sign_up_button'),
                  onPressed: () {
                    debugPrint('--> [AUTH:UI] Sign-up tapped (redirect=$redirectPath)');
                    context.push(
                      '${AppRoutes.login}?mode=signup&redirect=${Uri.encodeComponent(redirectPath)}',
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign Up",
                    style: context.textStyles.bodyMedium.copyWith(
                      color: context.palette.textMuted,
                    ),
                  ),
                ),

                // Clearance for floating bottom nav bar
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

