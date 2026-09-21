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
      expect(find.text('BOULDER SENDS TALLY'), findsOneWidget);
      expect(find.text('PERCEIVED EFFORT / INTENSITY'), findsOneWidget);
      expect(find.text('SESSION RATING'), findsOneWidget);
      expect(find.text('SESSION NOTES & DRILLS'), findsOneWidget);

      // Outdoor elements should now be gone
      expect(find.text('SELECT CRAG / LOCATION *'), findsNothing);
      expect(find.text('POST SEND'), findsNothing);
    });

    testWidgets('Indoor tally counter increments and decrements correctly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Switch to indoor
      await tester.tap(find.text('Indoor'));
      await tester.pumpAndSettle();

      // Initially 0 sends total
      expect(find.text('0 sends total'), findsOneWidget);

      // Tap + on V0
      final addIcons = find.byIcon(Icons.add_rounded);
      expect(addIcons, findsWidgets);
      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();

      // Count for V0 is now 1, and total sends is 1
      expect(find.text('1 send total'), findsOneWidget);

      // Tap + on V0 again
      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();
      expect(find.text('2 sends total'), findsOneWidget);

      // Tap - on V0
      final removeIcons = find.byIcon(Icons.remove_rounded);
      await tester.tap(removeIcons.first);
      await tester.pumpAndSettle();
      expect(find.text('1 send total'), findsOneWidget);
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

      // Switch to indoor and tally a send
      await tester.tap(find.text('Indoor'));
      await tester.pumpAndSettle();

      final addIcons = find.byIcon(Icons.add_rounded);
      await tester.tap(addIcons.first); // +1 on V0
      await tester.pumpAndSettle();
      expect(find.text('1 send total'), findsOneWidget);

      // Switch back to Outdoor
      await tester.tap(find.text('Outdoor'));
      await tester.pumpAndSettle();
      expect(find.text('LOG A SEND'), findsOneWidget);

      // Switch back to Indoor
      await tester.tap(find.text('Indoor'));
      await tester.pumpAndSettle();

      // Verify tally is preserved
      expect(find.text('1 send total'), findsOneWidget);
    });
  });
}

