import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/screens/mainscreen/MapScreen.dart';
import 'package:climbmy/widgets/built_in_flutter_map.dart';

void main() {
  Widget buildTestWidget() {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: const MapScreen(),
      ),
    );
  }

  group('MapScreen Tests', () {
    testWidgets(
        'MapScreen renders BuiltInFlutterMap, has no header, and renders sliding boulder list sheet',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1. Verify no header/AppBar exists
      expect(find.byType(AppBar), findsNothing);
      expect(find.text('Crags Map'), findsNothing);

      // 2. Verify BuiltInFlutterMap is rendered as the primary view with venues
      expect(find.byType(BuiltInFlutterMap), findsOneWidget);
      expect(find.byKey(const Key('built_in_flutter_map')), findsOneWidget);
      final mapWidget = tester.widget<BuiltInFlutterMap>(
          find.byKey(const Key('built_in_flutter_map')));
      expect(mapWidget.venues.isNotEmpty, isTrue);

      // 3. Verify DraggableScrollableSheet is rendered at the bottom
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
      expect(find.byKey(const Key('boulder_list_sheet')), findsOneWidget);
      expect(find.byKey(const Key('boulder_list_scroll_view')), findsOneWidget);
    });

    testWidgets(
        'Renders top venue filter bar and switches between All, Crags, and Gyms',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify filter bar and segments exist
      expect(find.byKey(const Key('venue_filter_bar')), findsOneWidget);
      expect(find.byKey(const Key('filter_all')), findsOneWidget);
      expect(find.byKey(const Key('filter_crags')), findsOneWidget);
      expect(find.byKey(const Key('filter_gyms')), findsOneWidget);

      // Tap Crags filter
      await tester.tap(find.byKey(const Key('filter_crags')));
      await tester.pumpAndSettle();

      final cragsMap = tester.widget<BuiltInFlutterMap>(
          find.byKey(const Key('built_in_flutter_map')));
      expect(cragsMap.venues.isNotEmpty, isTrue);
      expect(cragsMap.venues.every((v) => v.isOutdoor), isTrue);

      // Tap Gyms filter
      await tester.tap(find.byKey(const Key('filter_gyms')));
      await tester.pumpAndSettle();

      final gymsMap = tester.widget<BuiltInFlutterMap>(
          find.byKey(const Key('built_in_flutter_map')));
      expect(gymsMap.venues.isNotEmpty, isTrue);
      expect(gymsMap.venues.every((v) => v.isIndoor), isTrue);

      // Tap All filter
      await tester.tap(find.byKey(const Key('filter_all')));
      await tester.pumpAndSettle();

      final allMap = tester.widget<BuiltInFlutterMap>(
          find.byKey(const Key('built_in_flutter_map')));
      expect(allMap.venues.length, greaterThanOrEqualTo(gymsMap.venues.length));
    });

    testWidgets(
        'Renders zoom in/out and my location buttons and responds to taps',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('my_location_button')), findsOneWidget);
      expect(find.byKey(const Key('zoom_controls_container')), findsOneWidget);
      expect(find.byKey(const Key('zoom_in_button')), findsOneWidget);
      expect(find.byKey(const Key('zoom_out_button')), findsOneWidget);

      // Tap zoom in
      await tester.tap(find.byKey(const Key('zoom_in_button')));
      await tester.pumpAndSettle();

      // Tap zoom out
      await tester.tap(find.byKey(const Key('zoom_out_button')));
      await tester.pumpAndSettle();

      // Tap my location
      await tester.tap(find.byKey(const Key('my_location_button')));
      await tester.pumpAndSettle();
    });

    testWidgets('Sliding boulder sheet can be dragged up and down',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final containerFinder = find.byKey(const Key('boulder_sheet_container'));
      expect(containerFinder, findsOneWidget);

      // Get initial height of the sheet container
      final initialSize = tester.getSize(containerFinder);

      // Drag the sheet upwards
      await tester.drag(containerFinder, const Offset(0, -200));
      await tester.pumpAndSettle();

      // Expanded height should be larger than initial height
      final expandedSize = tester.getSize(containerFinder);
      expect(expandedSize.height, greaterThan(initialSize.height));

      // Drag the sheet downwards
      await tester.drag(containerFinder, const Offset(0, 200));
      await tester.pumpAndSettle();

      final collapsedSize = tester.getSize(containerFinder);
      expect(collapsedSize.height, lessThan(expandedSize.height));
    });
  });
}
