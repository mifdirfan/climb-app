import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/models/tick.dart';
import 'package:climbmy/providers/logbook_providers.dart';
import 'package:climbmy/screens/tick_history_screen.dart';
import 'package:climbmy/widgets/auth_required_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

const _routeStub = 'ROUTE_DETAIL_STUB';

final _routeDetailStub = GoRoute(
  path: AppRoutes.routeDetail,
  builder: (_, state) => Scaffold(body: Text('$_routeStub:${state.pathParameters['id']}')),
);

Future<RouterHarness> _pump(WidgetTester tester, Future<List<Tick>> Function() load) {
  return pumpRouterApp(
    tester,
    isAuthenticated: true,
    home: const TickHistoryScreen(),
    extraRoutes: [_routeDetailStub],
    overrides: [myTicksProvider.overrideWith((ref) => load())],
  );
}

void main() {
  group('TickHistoryScreen', () {
    testWidgets('guest sees sign-in gate redirecting back to tick history', (tester) async {
      final harness = await pumpRouterApp(tester, home: const TickHistoryScreen());

      expect(find.byType(AuthRequiredView), findsOneWidget);
      expect(find.text('Your Send Log'), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_view_sign_in_button')));
      await tester.pumpAndSettle();
      expect(harness.lastLogin!.queryParameters['redirect'], AppRoutes.tickHistory);
    });

    testWidgets('lists only the user\'s ticks with route, location, style and date', (tester) async {
      await _pump(tester, () async => [
            tick(id: 't1', routeName: 'Nyamuk', tickType: 'flash'),
            tick(id: 't2', routeName: 'Harimau', tickType: 'project', cragName: 'Bukit Tabur', sectorName: null),
          ]);

      expect(find.text('Nyamuk'), findsOneWidget);
      expect(find.text('Batu Caves • Damai Wall'), findsOneWidget);
      expect(find.text('FLASH'), findsOneWidget);
      expect(find.text('03 Nov 2026'), findsNWidgets(2));

      expect(find.text('Harimau'), findsOneWidget);
      expect(find.text('Bukit Tabur'), findsOneWidget);
      expect(find.text('PROJECT'), findsOneWidget);

      // Must not render the old all-venues list UI.
      expect(find.byKey(const Key('venues_search_field')), findsNothing);
    });

    testWidgets('summary counts clean sends, projects and distinct crags', (tester) async {
      await _pump(tester, () async => [
            tick(id: 't1', tickType: 'send'),
            tick(id: 't2', tickType: 'redpoint'),
            tick(id: 't3', tickType: 'project', cragName: 'Bukit Tabur'),
          ]);

      Finder statValue(String label) => find.descendant(
            of: find.ancestor(of: find.text(label), matching: find.byType(Column)).first,
            matching: find.byType(Text),
          ).first;

      expect(tester.widget<Text>(statValue('SENDS')).data, '2');
      expect(tester.widget<Text>(statValue('PROJECTS')).data, '1');
      expect(tester.widget<Text>(statValue('CRAGS')).data, '2');
    });

    testWidgets('tapping a tick opens its route detail', (tester) async {
      await _pump(tester, () async => [tick(id: 't1', routeId: 'route-42')]);

      await tester.tap(find.byKey(const Key('tick_item_t1')));
      await tester.pumpAndSettle();

      expect(find.text('$_routeStub:route-42'), findsOneWidget);
    });

    testWidgets('shows empty state when the user has no ticks', (tester) async {
      await _pump(tester, () async => []);

      expect(find.text('No ticks or sends logged yet'), findsOneWidget);
    });

    testWidgets('shows error state with retry on failure', (tester) async {
      var attempts = 0;
      await _pump(tester, () async {
        attempts++;
        if (attempts == 1) throw Exception('boom');
        return [tick()];
      });

      expect(find.text('Unable to load your send log'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(attempts, 2);
      expect(find.text('Nyamuk'), findsOneWidget);
    });
  });
}
