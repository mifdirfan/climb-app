import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/models/crag.dart';
import 'package:climbmy/providers/home_providers.dart';
import 'package:climbmy/screens/mainscreen/PostScreen.dart';

void main() {
  final testCrags = [
    const Crag(
      id: 'crag-outdoor-1',
      name: 'Batu Caves',
      state: 'Selangor',
      venueType: 'outdoor',
      routeCount: 45,
    ),
    const Crag(
      id: 'crag-indoor-1',
      name: 'Camp5 1 Utama',
      state: 'Selangor',
      venueType: 'indoor',
      routeCount: 150,
    ),
  ];

  Widget buildTestWidget({PostPage? child}) {
    return ProviderScope(
      overrides: [
        cragsProvider.overrideWith((ref) => Future.value(testCrags)),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: child ?? const PostPage(),
      ),
    );
  }

  group('PostScreen Dynamic Form & State Management Tests', () {
    testWidgets('Renders outdoor send form by default', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Top toggle button exists with both options
      expect(find.text('Outdoor'), findsOneWidget);
      expect(find.text('Indoor'), findsOneWidget);

      // Outdoor form elements are present
      expect(find.text('LOG A SEND'), findsOneWidget);
      expect(find.text('SELECT CRAG / LOCATION *'), findsOneWidget);
      expect(find.text('ASCENT STYLE'), findsOneWidget);
      expect(find.text('POST SEND'), findsOneWidget);

      // Indoor form elements should not be present
      expect(find.text('SELECT CLIMBING GYM *'), findsNothing);
      expect(find.text('BOULDER SENDS TALLY'), findsNothing);
      expect(find.text('LOG GYM SESSION'), findsNothing);
    });

    testWidgets('Tapping Indoor switches to gym session form', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Indoor' pill button
      final indoorBtn = find.text('Indoor');
      await tester.tap(indoorBtn);
      await tester.pumpAndSettle();

      // Title updates
      expect(find.text('LOG GYM SESSION'), findsNWidgets(2)); // AppBar title & Submit CTA button
      expect(find.text('SELECT CLIMBING GYM *'), findsOneWidget);
      expect(find.text('SESSION DATE'), findsOneWidget);
      expect(find.text('DURATION (MIN)'), findsOneWidget);
      expect(find.text('INTENSITY'), findsOneWidget);
      expect(find.text('SESSION RATING'), findsOneWidget);
      expect(find.text('SESSION NOTES & DRILLS'), findsOneWidget);

      // Outdoor elements should now be gone
      expect(find.text('SELECT CRAG / LOCATION *'), findsNothing);
      expect(find.text('POST SEND'), findsNothing);
    });

    testWidgets('Perceived effort selector toggles options', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Indoor'));
      await tester.pumpAndSettle();

      // Tap 'Hard' effort
      final hardOption = find.text('Hard');
      expect(hardOption, findsOneWidget);
      await tester.tap(hardOption);
      await tester.pumpAndSettle();

      // Tap 'Limit' effort
      final limitOption = find.text('Limit');
      expect(limitOption, findsOneWidget);
      await tester.tap(limitOption);
      await tester.pumpAndSettle();
    });

    testWidgets('Rating bar updates rating', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Indoor'));
      await tester.pumpAndSettle();

      // Default rating is 4 / 5
      expect(find.text('4 / 5'), findsOneWidget);

      // Tap the 5th star
      final stars = find.byIcon(Icons.star_rounded);
      expect(stars, findsWidgets);
    });

    testWidgets('Switching back and forth preserves form state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to indoor and select 'Hard' effort
      await tester.tap(find.text('Indoor'));
      await tester.pumpAndSettle();

      final hardOption = find.text('Hard');
      await tester.tap(hardOption);
      await tester.pumpAndSettle();

      // Switch back to Outdoor
      await tester.tap(find.text('Outdoor'));
      await tester.pumpAndSettle();
      expect(find.text('LOG A SEND'), findsOneWidget);

      // Switch back to Indoor
      await tester.tap(find.text('Indoor'));
      await tester.pumpAndSettle();

      // Verify selected effort is preserved
      expect(find.text('Hard'), findsOneWidget);
    });

    testWidgets('OutdoorForm uses VenuePickerBottomSheet for selecting crag and route', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open venue picker bottom sheet
      final pickerTrigger = find.byKey(const Key('crag_picker_trigger'));
      expect(pickerTrigger, findsOneWidget);
      await tester.tap(pickerTrigger);
      await tester.pumpAndSettle();

      // Sheet is visible and filters outdoor only: Batu Caves is shown, Camp5 is filtered out
      expect(find.text('Select Crag & Route'), findsOneWidget);
      expect(find.text('Batu Caves'), findsOneWidget);
      expect(find.text('Camp5 1 Utama'), findsNothing);

      // Select Batu Caves
      await tester.tap(find.text('Batu Caves'));
      await tester.pumpAndSettle();

      // Route dropdown section appears
      final routeDropdown = find.byKey(const Key('crag_route_dropdown'));
      expect(routeDropdown, findsOneWidget);

      // Open route dropdown and choose 'Banana Jam'
      await tester.tap(routeDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Banana Jam'), findsWidgets);
      await tester.tap(find.text('Banana Jam').last);
      await tester.pumpAndSettle();

      // Tap confirmation button
      final confirmBtn = find.text('SELECT CRAG & ROUTE');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Crag & route are displayed in Section B
      expect(find.text('Batu Caves (Selangor)'), findsOneWidget);
      expect(find.textContaining('Banana Jam'), findsWidgets);
      expect(find.textContaining('6b+'), findsWidgets);

      // Section C Route name text field is auto-populated
      final routeInputFinder = find.byKey(const Key('route_name_input'));
      await tester.ensureVisible(routeInputFinder);
      final routeField = tester.widget<TextFormField>(routeInputFinder);
      expect(routeField.controller?.text, 'Banana Jam');

      // Grade dropdown reflects the selected route grade ('6b+')
      expect(find.text('6b+'), findsOneWidget);

      // Browse routes link and route picker button are visible when a crag is selected
      expect(find.byKey(const Key('browse_routes_link')), findsOneWidget);
      expect(find.byKey(const Key('route_picker_button')), findsOneWidget);

      // Tapping route picker button re-opens picker with existing selection
      await tester.tap(find.byKey(const Key('route_picker_button')));
      await tester.pumpAndSettle();
      expect(find.text('Select Crag & Route'), findsOneWidget);
    });
  });
}

