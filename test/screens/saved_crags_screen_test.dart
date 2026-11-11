import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/models/crag.dart';
import 'package:climbmy/providers/home_providers.dart';
import 'package:climbmy/providers/logbook_providers.dart';
import 'package:climbmy/screens/saved_crags_screen.dart';
import 'package:climbmy/widgets/auth_required_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

/// Serves a fixed list instead of hitting Supabase.
class _FakeSavedCrags extends SavedCragsNotifier {
  _FakeSavedCrags(this._items);
  final List<Crag> _items;

  @override
  Future<List<Crag>> build() async => _items;
}

const _cragStub = 'CRAG_DETAIL_STUB';

Future<RouterHarness> _pump(WidgetTester tester, List<Crag> saved) {
  return pumpRouterApp(
    tester,
    isAuthenticated: true,
    home: const SavedCragsScreen(),
    extraRoutes: [
      GoRoute(
        path: AppRoutes.cragDetail,
        builder: (_, state) => Scaffold(body: Text('$_cragStub:${state.pathParameters['id']}')),
      ),
    ],
    overrides: [
      savedCragsProvider.overrideWith(() => _FakeSavedCrags(saved)),
      // Tripwire: the screen must NOT fall back to the all-venues source.
      mapVenuesProvider.overrideWith((ref) async => throw StateError('mapVenuesProvider must not be read')),
    ],
  );
}

void main() {
  group('SavedCragsScreen', () {
    testWidgets('guest sees sign-in gate redirecting back to saved crags', (tester) async {
      final harness = await pumpRouterApp(tester, home: const SavedCragsScreen());

      expect(find.byType(AuthRequiredView), findsOneWidget);
      expect(find.text('Your Saved Crags'), findsOneWidget);

      await tester.tap(find.byKey(const Key('auth_view_sign_in_button')));
      await tester.pumpAndSettle();
      expect(harness.lastLogin!.queryParameters['redirect'], AppRoutes.savedCrags);
    });

    testWidgets('lists only saved crags, without the gym/crag filter chips', (tester) async {
      await _pump(tester, [cragBatuCaves]);

      expect(find.text('Batu Caves'), findsOneWidget);
      expect(find.text('Bukit Tabur'), findsNothing);
      expect(find.byKey(const Key('filter_gyms')), findsNothing);
      expect(find.text('Unable to load places'), findsNothing);
    });

    testWidgets('search filters within saved crags', (tester) async {
      await _pump(tester, [cragBatuCaves, cragBukitTabur]);

      await tester.enterText(find.byKey(const Key('venues_search_field')), 'tabur');
      await tester.pumpAndSettle();

      expect(find.text('Bukit Tabur'), findsOneWidget);
      expect(find.text('Batu Caves'), findsNothing);
    });

    testWidgets('tapping a saved crag opens its detail page', (tester) async {
      await _pump(tester, [cragBatuCaves]);

      await tester.tap(find.byKey(const Key('venue_item_crag-1')));
      await tester.pumpAndSettle();

      expect(find.text('$_cragStub:crag-1'), findsOneWidget);
    });

    testWidgets('shows bookmark hint when nothing is saved', (tester) async {
      await _pump(tester, []);

      expect(find.text('No saved crags yet'), findsOneWidget);
      expect(find.text('Tap the bookmark icon on any crag to save it here.'), findsOneWidget);
    });
  });
}
