import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/models/crag.dart';
import 'package:climbmy/widgets/crag_card.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('AppTheme & Color Palette Tests', () {
    test('Prime color #CFFF74 is applied to dark and light themes', () {
      const expectedPrimeColor = Color(0xFFCFFF74);
      const expectedOnPrimary = Color(0xFF11140E);

      expect(AppColors.primary, equals(expectedPrimeColor));
      expect(AppColors.onPrimary, equals(expectedOnPrimary));

      expect(AppTheme.darkTheme.colorScheme.primary, equals(expectedPrimeColor));
      expect(AppTheme.darkTheme.colorScheme.onPrimary, equals(expectedOnPrimary));

      expect(AppTheme.lightTheme.colorScheme.primary, equals(expectedPrimeColor));
      expect(AppTheme.lightTheme.colorScheme.onPrimary, equals(expectedOnPrimary));
    });

    test('Dark and Light themes have correct scaffold background and surfaces', () {
      expect(AppTheme.darkTheme.scaffoldBackgroundColor, equals(const Color(0xFF121212)));
      expect(AppTheme.darkTheme.brightness, equals(Brightness.dark));

      expect(AppTheme.lightTheme.scaffoldBackgroundColor, equals(const Color(0xFFF8F9FA)));
      expect(AppTheme.lightTheme.brightness, equals(Brightness.light));
    });

    testWidgets('CragCard renders flat solid surface with no gradients', (tester) async {
      const testCrag = Crag(
        id: 'crag-1',
        name: 'Batu Caves',
        state: 'Selangor',
        routeCount: 45,
        styles: ['SPORT', 'BOULDER'],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: CragCard(crag: testCrag),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all Container / DecoratedBox widgets within CragCard
      final containers = tester.widgetList<Container>(find.descendant(
        of: find.byType(CragCard),
        matching: find.byType(Container),
      ));

      for (final container in containers) {
        final decoration = container.decoration;
        if (decoration is BoxDecoration) {
          expect(decoration.gradient, isNull,
              reason: 'No gradients should be present in CragCard');
        }
      }
    });

    testWidgets('App adapts correctly under Light and Dark mode rendering', (tester) async {
      const testCrag = Crag(
        id: 'crag-1',
        name: 'Camp5',
        state: 'Selangor',
        venueType: 'indoor',
        routeCount: 120,
      );

      // 1. Render in Dark mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: const Scaffold(
            body: CragCard(crag: testCrag),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Camp5'), findsOneWidget);

      // 2. Render in Light mode
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const Scaffold(
            body: CragCard(crag: testCrag),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Camp5'), findsOneWidget);
    });
  });
}

