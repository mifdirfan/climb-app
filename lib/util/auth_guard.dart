import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../providers/auth_providers.dart';

/// Executes [action] if signed in; otherwise prompts the user to log in.
void requireAuth(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback action,
  String reason = 'Sign in to access this feature',
}) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);

  if (isAuthenticated) {
    action();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reason),
        action: SnackBarAction(
          label: 'SIGN IN',
          onPressed: () {
            String? currentUri;
            try {
              currentUri = GoRouterState.of(context).uri.toString();
            } catch (_) {}

            if (currentUri != null && currentUri.isNotEmpty && currentUri != AppRoutes.login) {
              context.push('${AppRoutes.login}?redirect=${Uri.encodeComponent(currentUri)}');
            } else {
              context.push(AppRoutes.login);
            }
          },
        ),
      ),
    );
  }
}