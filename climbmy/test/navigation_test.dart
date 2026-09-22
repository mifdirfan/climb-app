import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climbmy/main.dart';
import 'package:climbmy/providers/home_providers.dart';
import 'package:climbmy/screens/mainscreen/MapScreen.dart';

void main() {
  group('GoRouter Navigation Tests', () {
    testWidgets('Tapping bottom nav bar items routes between Crags, Map, Ticks, and Profile',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cragsProvider.overrideWith((ref) => Future.value([])),
            recentRoutesProvider.overrideWith((ref) => Future.value([])),
            hazardAlertsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const ClimbMYApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Initially at /crags (HomeScreen)
      expect(find.text('Crag'), findsOneWidget);
      expect(find.text('Popular Crags'), findsOneWidget);

      // 2. Tap 'Map' nav item (index 1) -> /map
      final mapIcon = find.byIcon(Icons.map_outlined);
      expect(mapIcon, findsOneWidget);
      await tester.tap(mapIcon);
      await tester.pumpAndSettle();

      // Verify MapScreen is active with GoogleMap and sliding boulder sheet
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.byKey(const Key('google_map')), findsOneWidget);
      expect(find.byKey(const Key('boulder_list_sheet')), findsOneWidget);

      // 3. Tap 'Ticks' nav item (index 2) -> /ticks (PostScreen)
      final ticksIcon = find.byIcon(Icons.check_circle_outline_rounded);
      expect(ticksIcon, findsOneWidget);
      await tester.tap(ticksIcon);
      await tester.pumpAndSettle();

      // Verify PostScreen is active
      expect(find.text('LOG A SEND'), findsOneWidget);
      expect(find.text('POST SEND'), findsOneWidget);

      // 4. Tap 'Profile' nav item (index 3) -> /profile (ProfileScreen)
      final profileIcon = find.byIcon(Icons.person_outline_rounded);
      expect(profileIcon, findsOneWidget);
      await tester.tap(profileIcon);
      await tester.pumpAndSettle();

      // Verify ProfileScreen is active
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Malaysian Climber'), findsOneWidget);

      // 5. Tap 'Crags' nav item (index 0) -> /crags (HomeScreen)
      final cragsIcon = find.byIcon(Icons.explore_outlined);
      expect(cragsIcon, findsOneWidget);
      await tester.tap(cragsIcon);
      await tester.pumpAndSettle();

      // Verify returned to Crags view
      expect(find.text('Crag'), findsOneWidget);
      expect(find.text('Popular Crags'), findsOneWidget);
    });

    testWidgets('Tapping SUBMIT NEW ROUTE button navigates to /ticks branch', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cragsProvider.overrideWith((ref) => Future.value([])),
            recentRoutesProvider.overrideWith((ref) => Future.value([])),
            hazardAlertsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const ClimbMYApp(),
        ),
      );

      await tester.pumpAndSettle();

      final submitBtn = find.text('SUBMIT NEW ROUTE');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('LOG A SEND'), findsOneWidget);
      expect(find.text('POST SEND'), findsOneWidget);
    });

    testWidgets('Tapping Crags in bottom nav on MapScreen routes back to /crags', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cragsProvider.overrideWith((ref) => Future.value([])),
            recentRoutesProvider.overrideWith((ref) => Future.value([])),
            hazardAlertsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const ClimbMYApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to /map
      await tester.tap(find.byIcon(Icons.map_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.byKey(const Key('google_map')), findsOneWidget);

      // Tap Crags nav item in bottom nav
      final cragsIcon = find.byIcon(Icons.explore_outlined);
      expect(cragsIcon, findsOneWidget);
      await tester.tap(cragsIcon);
      await tester.pumpAndSettle();

      // Returns to Crags
      expect(find.text('Popular Crags'), findsOneWidget);
    });
  });
}
