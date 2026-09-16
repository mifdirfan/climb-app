import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/models/crag.dart';
import 'package:climbmy/models/route_item.dart';
import 'package:climbmy/models/hazard_alert.dart';
import 'package:climbmy/providers/home_providers.dart';
import 'package:climbmy/screens/mainscreen/HomeScreen.dart';
import 'package:climbmy/widgets/grade_chip.dart';
import 'package:climbmy/widgets/hazard_alert_banner.dart';
import 'package:climbmy/widgets/crag_card.dart';
import 'package:climbmy/widgets/route_item_card.dart';

void main() {
  group('Extracted Widgets Tests', () {
    testWidgets('GradeChip renders grade text and styling', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GradeChip(grade: '6b+'),
          ),
        ),
      );

      expect(find.text('6b+'), findsOneWidget);
    });

    testWidgets('HazardAlertBanner renders custom hazard alert', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HazardAlertBanner(
              customMessage: '⚠️ Loose rock reported at White Wall',
            ),
          ),
        ),
      );

      expect(find.text('⚠️ Loose rock reported at White Wall'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('CragCard renders crag details', (tester) async {
      const crag = Crag(
        id: 'crag-1',
        name: 'Batu Caves',
        state: 'Selangor',
        routeCount: 120,
        styles: ['SPORT', 'TRAD'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: CragCard(crag: crag),
          ),
        ),
      );

      expect(find.text('Batu Caves'), findsOneWidget);
      expect(find.text('Selangor'), findsOneWidget);
      expect(find.text('120+ Routes'), findsOneWidget);
      expect(find.text('SPORT'), findsOneWidget);
      expect(find.text('TRAD'), findsOneWidget);
    });

    testWidgets('RouteItemCard renders route info and grade chip', (tester) async {
      const route = RouteItem(
        id: 'route-1',
        sectorId: 'sector-1',
        name: 'The Grunt',
        grade: '7a',
        sectorName: 'Damai Wall',
        cragName: 'Batu Caves',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: RouteItemCard(route: route),
          ),
        ),
      );

      expect(find.text('The Grunt'), findsOneWidget);
      expect(find.text('7a'), findsOneWidget);
      expect(find.text('Damai Wall, Batu Caves'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('HomeScreen States Tests', () {
    testWidgets('HomeScreen renders empty states when providers return empty lists', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cragsProvider.overrideWith((ref) => Future.value([])),
            recentRoutesProvider.overrideWith((ref) => Future.value([])),
            hazardAlertsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Crag'), findsOneWidget);
      expect(find.text('Search Crag'), findsOneWidget);
      expect(find.text('Popular Crags'), findsOneWidget);
      expect(find.text('Recently Added Routes'), findsOneWidget);
      expect(find.text('SUBMIT NEW ROUTE'), findsOneWidget);
      // Empty state displays "No items found"
      expect(find.text('No items found'), findsNWidgets(2));
    });

    testWidgets('HomeScreen renders populated crags and routes data', (tester) async {
      final mockCrags = [
        const Crag(
          id: 'c1',
          name: 'Bukit Takun',
          state: 'Selangor',
          routeCount: 45,
          styles: ['SPORT'],
        ),
      ];

      final mockRoutes = [
        const RouteItem(
          id: 'r1',
          sectorId: 's1',
          name: 'Crimpy Business',
          grade: '6b+',
          sectorName: 'White Wall',
          cragName: 'Bukit Takun',
        ),
      ];

      final mockAlerts = [
        const HazardAlert(
          id: 'h1',
          sectorId: 's1',
          hazardType: 'wasps',
          description: 'Active nest near bolt 3',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cragsProvider.overrideWith((ref) => Future.value(mockCrags)),
            recentRoutesProvider.overrideWith((ref) => Future.value(mockRoutes)),
            hazardAlertsProvider.overrideWith((ref) => Future.value(mockAlerts)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bukit Takun'), findsOneWidget);
      expect(find.text('Crimpy Business'), findsOneWidget);
      expect(find.text('WASPS: Active nest near bolt 3'), findsOneWidget);
    });

    testWidgets('HomeScreen renders error state cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cragsProvider.overrideWith((ref) => Future.error('Database unreachable')),
            recentRoutesProvider.overrideWith((ref) => Future.error('Timeout')),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Error loading crags: Database unreachable'), findsOneWidget);
      expect(find.textContaining('Error loading routes: Timeout'), findsOneWidget);
    });
  });
}

