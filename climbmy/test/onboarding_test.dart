import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/screens/onboarding.dart';
import 'package:climbmy/widgets/dots_indicator.dart';
import 'package:climbmy/providers/home_providers.dart';

void main() {
  group('DotsIndicator Widget Tests', () {
    testWidgets('renders correct number of dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DotsIndicator(
              itemCount: 3,
              currentIndex: 0,
            ),
          ),
        ),
      );

      // Find all animated containers (3 dots)
      final containers = find.byType(AnimatedContainer);
      expect(containers, findsNWidgets(3));
    });
  });

  group('OnboardingScreen Tests', () {
    testWidgets('renders first slide with Offline Topos', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      expect(find.text('Crag'), findsOneWidget);
      expect(find.text('Offline Topos'), findsOneWidget);
      expect(find.textContaining('Never lose your route map'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
    });

    testWidgets('swiping page or tapping NEXT advances to next slide', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Tap NEXT
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('Real-Time Hazard Alerts'), findsOneWidget);
      expect(find.text('NEXT'), findsOneWidget);

      // Tap NEXT again to reach last slide
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      expect(find.text('Log Your Ascents'), findsOneWidget);
      expect(find.text('GET STARTED'), findsOneWidget);
    });

    testWidgets('tapping SKIP navigates to HomeScreen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cragsProvider.overrideWith((ref) => Future.value([])),
            recentRoutesProvider.overrideWith((ref) => Future.value([])),
            hazardAlertsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const OnboardingScreen(),
          ),
        ),
      );

      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      // Should be on HomeScreen
      expect(find.text('Popular Crags'), findsOneWidget);
      expect(find.text('Recently Added Routes'), findsOneWidget);
    });
  });
}

