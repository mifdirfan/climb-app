import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/widgets/auth_required_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  const signInKey = Key('auth_view_sign_in_button');
  const signUpKey = Key('auth_view_sign_up_button');

  group('AuthRequiredView rendering', () {
    testWidgets('shows title, subtitle, category label and both CTAs', (tester) async {
      await pumpRouterApp(
        tester,
        home: const AuthRequiredView(
          title: 'Custom Title',
          subtitle: 'Custom subtitle',
          categoryLabel: 'LOCKED',
        ),
      );

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom subtitle'), findsOneWidget);
      expect(find.text('LOCKED'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.byKey(signInKey), findsOneWidget);
      expect(find.byKey(signUpKey), findsOneWidget);
    });

    testWidgets('omits subtitle and category label when null', (tester) async {
      await pumpRouterApp(
        tester,
        home: const AuthRequiredView(
          title: 'Only Title',
          subtitle: null,
          categoryLabel: null,
        ),
      );

      expect(find.text('Only Title'), findsOneWidget);
      expect(find.text('SIGN IN REQUIRED'), findsNothing);
    });
  });

  group('AuthRequiredView navigation', () {
    testWidgets('SIGN IN pushes login with encoded redirect', (tester) async {
      final harness = await pumpRouterApp(
        tester,
        home: const AuthRequiredView(redirectPath: AppRoutes.reportHazardSelect),
      );

      await tester.tap(find.byKey(signInKey));
      await tester.pumpAndSettle();

      expect(find.text(loginStubText), findsOneWidget);
      final uri = harness.lastLogin!;
      expect(uri.path, AppRoutes.login);
      expect(uri.queryParameters['redirect'], AppRoutes.reportHazardSelect);
      expect(uri.queryParameters.containsKey('mode'), isFalse);
    });

    testWidgets('Sign Up pushes login in signup mode with redirect', (tester) async {
      final harness = await pumpRouterApp(
        tester,
        home: const AuthRequiredView(), // default redirect = ticks
      );

      await tester.tap(find.byKey(signUpKey));
      await tester.pumpAndSettle();

      final uri = harness.lastLogin!;
      expect(uri.queryParameters['mode'], 'signup');
      expect(uri.queryParameters['redirect'], AppRoutes.ticks);
    });
  });

  group('AuthRequiredView back button', () {
    testWidgets('hidden at root when no onBack and showAppBar is false', (tester) async {
      await pumpRouterApp(tester, home: const AuthRequiredView());

      expect(find.byType(AppBar), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('shown when showAppBar is true', (tester) async {
      await pumpRouterApp(tester, home: const AuthRequiredView(showAppBar: true));

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });

    testWidgets('invokes custom onBack when provided', (tester) async {
      var backCalls = 0;
      await pumpRouterApp(
        tester,
        home: AuthRequiredView(onBack: () => backCalls++),
      );

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(backCalls, 1);
    });
  });
}
