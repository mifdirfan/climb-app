import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/screens/hazard_report/select_hazard_type_screen.dart';
import 'package:climbmy/screens/mainscreen/PostScreen.dart';
import 'package:climbmy/util/hazard_type.dart';
import 'package:climbmy/widgets/auth_required_view.dart';
import 'package:climbmy/widgets/report_hazard_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/pump_app.dart';

const _signInKey = Key('auth_view_sign_in_button');

void main() {
  group('SelectHazardTypeScreen auth gate', () {
    testWidgets('guest sees AuthRequiredView with back button', (tester) async {
      await pumpRouterApp(tester, home: const SelectHazardTypeScreen());

      expect(find.byType(AuthRequiredView), findsOneWidget);
      expect(find.text('Report Crag Hazards'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.text(HazardType.looseRock.title), findsNothing);
    });

    testWidgets('guest sign-in redirects back to hazard select', (tester) async {
      final harness = await pumpRouterApp(tester, home: const SelectHazardTypeScreen());

      await tester.tap(find.byKey(_signInKey));
      await tester.pumpAndSettle();

      expect(harness.lastLogin!.queryParameters['redirect'], AppRoutes.reportHazardSelect);
    });

    testWidgets('authenticated user sees hazard categories', (tester) async {
      await pumpRouterApp(
        tester,
        isAuthenticated: true,
        home: const SelectHazardTypeScreen(),
      );

      expect(find.byType(AuthRequiredView), findsNothing);
      expect(find.text(HazardType.looseRock.title), findsOneWidget);
    });

    testWidgets('rebuilds into the real screen as soon as auth flips', (tester) async {
      final harness = await pumpRouterApp(tester, home: const SelectHazardTypeScreen());
      expect(find.byType(AuthRequiredView), findsOneWidget);

      harness.signIn();
      await tester.pumpAndSettle();

      expect(find.byType(AuthRequiredView), findsNothing);
      expect(find.text(HazardType.looseRock.title), findsOneWidget);
    });
  });

  group('PostPage auth gate', () {
    testWidgets('guest sees log-sends gate, no back button at root', (tester) async {
      await pumpRouterApp(tester, home: const PostPage());

      expect(find.byType(AuthRequiredView), findsOneWidget);
      expect(find.text('Sign In to Log Sends'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('guest sign-in redirects back to ticks', (tester) async {
      final harness = await pumpRouterApp(tester, home: const PostPage());

      await tester.tap(find.byKey(_signInKey));
      await tester.pumpAndSettle();

      expect(harness.lastLogin!.queryParameters['redirect'], AppRoutes.ticks);
    });

    testWidgets('guest with onBack gets a back button wired to it', (tester) async {
      var backCalls = 0;
      await pumpRouterApp(tester, home: PostPage(onBack: () => backCalls++));

      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      expect(backCalls, 1);
    });
  });

  group('End-to-end guest hazard flow', () {
    testWidgets('FAB -> hazard gate -> login carries hazard redirect', (tester) async {
      final harness = await pumpRouterApp(
        tester,
        home: const Scaffold(floatingActionButton: ReportHazardButton()),
        extraRoutes: [
          GoRoute(
            path: AppRoutes.reportHazardSelect,
            builder: (_, _) => const SelectHazardTypeScreen(),
          ),
        ],
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Report Crag Hazards'), findsOneWidget);
      expect(harness.loginVisits, isEmpty);

      await tester.tap(find.byKey(_signInKey));
      await tester.pumpAndSettle();

      expect(harness.loginVisits, hasLength(1));
      expect(harness.lastLogin!.queryParameters['redirect'], AppRoutes.reportHazardSelect);
    });
  });
}
