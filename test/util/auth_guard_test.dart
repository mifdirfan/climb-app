import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/util/auth_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/pump_app.dart';

/// Minimal consumer that calls [requireAuth] on tap.
class _GuardedButton extends ConsumerWidget {
  const _GuardedButton({required this.onAction});
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => requireAuth(context, ref, action: onAction),
          child: const Text('GUARDED'),
        ),
      ),
    );
  }
}

void main() {
  group('requireAuth', () {
    testWidgets('runs action and does not navigate when authenticated', (tester) async {
      var calls = 0;
      final harness = await pumpRouterApp(
        tester,
        isAuthenticated: true,
        home: _GuardedButton(onAction: () => calls++),
      );

      await tester.tap(find.text('GUARDED'));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(harness.loginVisits, isEmpty);
      expect(find.text('GUARDED'), findsOneWidget);
    });

    testWidgets('skips action and redirects guest to login with current URI', (tester) async {
      var calls = 0;
      final harness = await pumpRouterApp(
        tester,
        initialLocation: '/guarded?crag=abc 1',
        home: const SizedBox.shrink(),
        extraRoutes: [
          GoRoute(
            path: '/guarded',
            builder: (_, _) => _GuardedButton(onAction: () => calls++),
          ),
        ],
      );

      await tester.tap(find.text('GUARDED'));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(find.text(loginStubText), findsOneWidget);

      final redirect = Uri.parse(harness.lastLogin!.queryParameters['redirect']!);
      expect(redirect.path, '/guarded');
      expect(redirect.queryParameters['crag'], 'abc 1',
          reason: 'query params of the origin must survive the round-trip encoding');
    });

    testWidgets('after a redirect, signing in lets the same tap run the action', (tester) async {
      var calls = 0;
      final harness = await pumpRouterApp(
        tester,
        home: _GuardedButton(onAction: () => calls++),
      );

      await tester.tap(find.text('GUARDED'));
      await tester.pumpAndSettle();
      expect(calls, 0);

      harness.signIn();
      harness.router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('GUARDED'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(harness.loginVisits, hasLength(1));
      expect(harness.lastLogin!.path, AppRoutes.login);
    });
  });
}
