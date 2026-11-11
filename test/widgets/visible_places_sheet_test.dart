import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/models/crag.dart';
import 'package:climbmy/widgets/visible_places_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/fixtures.dart';
import '../helpers/pump_app.dart';

const _cragStub = 'CRAG_DETAIL_STUB';

/// Records the `extra` handed to the detail route so we can assert the
/// tapped [Crag] is forwarded for instant rendering.
Object? _lastExtra;

final _cragDetailStub = GoRoute(
  path: AppRoutes.cragDetail,
  builder: (_, state) {
    _lastExtra = state.extra;
    return Scaffold(body: Text('$_cragStub:${state.pathParameters['id']}'));
  },
);

Widget _host({ValueChanged<Crag>? onVenueTap}) => Scaffold(
      body: Stack(
        children: [
          VisiblePlacesSheet(
            venues: const [cragBatuCaves, cragBukitTabur],
            onVenueTap: onVenueTap,
          ),
        ],
      ),
    );

/// The sheet starts collapsed (14%); drag it open so rows are hittable.
Future<void> _expandSheet(WidgetTester tester) async {
  await tester.drag(find.byKey(const Key('boulder_list_scroll_view')), const Offset(0, -400));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => _lastExtra = null);

  group('VisiblePlacesSheet', () {
    testWidgets('tapping a venue opens its crag detail page', (tester) async {
      await pumpRouterApp(tester, home: _host(), extraRoutes: [_cragDetailStub]);
      await _expandSheet(tester);

      await tester.tap(find.byKey(const Key('visible_venue_crag-2')));
      await tester.pumpAndSettle();

      expect(find.text('$_cragStub:crag-2'), findsOneWidget);
      expect(_lastExtra, same(cragBukitTabur),
          reason: 'the tapped Crag is passed as extra so detail renders instantly');
    });

    testWidgets('custom onVenueTap overrides default navigation', (tester) async {
      Crag? tapped;
      await pumpRouterApp(
        tester,
        home: _host(onVenueTap: (c) => tapped = c),
        extraRoutes: [_cragDetailStub],
      );
      await _expandSheet(tester);

      await tester.tap(find.byKey(const Key('visible_venue_crag-1')));
      await tester.pumpAndSettle();

      expect(tapped, same(cragBatuCaves));
      expect(find.textContaining(_cragStub), findsNothing);
    });
  });
}
