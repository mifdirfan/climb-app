import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../providers/auth_providers.dart';

/// Runs [action] if signed in; otherwise pushes the login route, passing the
/// current location as `redirect` so the user returns here after login.
///
/// Use this for guarding *actions* on an already-visible screen (e.g. submit).
/// For guarding whole *screens*, render `AuthRequiredView` from the screen itself.
///
/// @source Riverpod:isAuthenticatedProvider, GoRouterState (current URI)
/// @sink   GoRouter navigation stack (`/login?redirect=...`)
/// @breaking Removed the unused `reason` parameter.
void requireAuth(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback action,
}) {
  final isAuthenticated = ref.read(isAuthenticatedProvider);
  if (isAuthenticated) {
    action();
    return;
  }

  String? currentUri;
  try {
    currentUri = GoRouterState.of(context).uri.toString();
  } catch (_) {}

  final loginUri = (currentUri != null && currentUri.isNotEmpty && currentUri != AppRoutes.login)
      ? '${AppRoutes.login}?redirect=${Uri.encodeComponent(currentUri)}'
      : AppRoutes.login;

  debugPrint('--> [AUTH:UI] Guest blocked, redirecting to $loginUri');
  context.push(loginUri);
}
