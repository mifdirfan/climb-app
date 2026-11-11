import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/widgets/report_hazard_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/pump_app.dart';

const _hazardStub = 'HAZARD_SELECT_STUB';

Widget _host(Widget fab) => Scaffold(floatingActionButton: fab);

final _hazardRoute = GoRoute(
  path: AppRoutes.reportHazardSelect,
  builder: (_, _) => const Scaffold(body: Text(_hazardStub)),
);

void main() {
  group('ReportHazardButton', () {
    testWidgets('extended variant shows label; compact variant uses tooltip', (tester) async {
      await pumpRouterApp(tester, home: _host(const ReportHazardButton()));
      expect(find.text('REPORT'), findsOneWidget);

      await pumpRouterApp(tester, home: _host(const ReportHazardButton(extended: false)));
      expect(find.text('REPORT'), findsNothing);
      expect(find.byTooltip('REPORT'), findsOneWidget);
    });

    testWidgets('guest tap goes straight to hazard select, not login (V2)', (tester) async {
      final harness = await pumpRouterApp(
        tester,
        isAuthenticated: false,
        home: _host(const ReportHazardButton()),
        extraRoutes: [_hazardRoute],
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(_hazardStub), findsOneWidget);
      expect(harness.loginVisits, isEmpty);
    });

    testWidgets('custom onPressed overrides default navigation', (tester) async {
      var taps = 0;
      await pumpRouterApp(
        tester,
        home: _host(ReportHazardButton(onPressed: () => taps++)),
        extraRoutes: [_hazardRoute],
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(find.text(_hazardStub), findsNothing);
    });
  });
}
