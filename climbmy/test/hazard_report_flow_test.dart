import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:climbmy/main.dart';
import 'package:climbmy/models/crag.dart';
import 'package:climbmy/providers/home_providers.dart';
import 'package:climbmy/screens/hazard_report/select_hazard_type_screen.dart';
import 'package:climbmy/screens/hazard_report/report_hazard_form_screen.dart';
import 'package:climbmy/screens/hazard_report/report_confirmation_screen.dart';
import 'package:climbmy/widgets/form/venue_picker_bottom_sheet.dart';
import 'package:climbmy/widgets/report_hazard_button.dart';

void main() {
  const mockOutdoorCrag = Crag(
    id: 'crag-1',
    name: 'Batu Caves',
    state: 'Selangor',
    venueType: 'outdoor',
    routeCount: 120,
    styles: ['SPORT'],
  );

  const mockIndoorGym = Crag(
    id: 'gym-1',
    name: 'Camp5 1 Utama',
    state: 'Selangor',
    venueType: 'indoor',
    routeCount: 80,
    styles: ['BOULDER'],
  );

  group('Hazard Reporting Screen Unit Tests', () {
    testWidgets('SelectHazardTypeScreen renders all hazard categories', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SelectHazardTypeScreen(),
          ),
        ),
      );

      expect(find.text('REPORT HAZARD'), findsOneWidget);
      expect(find.text('Select Hazard Type'), findsOneWidget);
      expect(find.text('Loose Rock'), findsOneWidget);
      expect(find.text('Wasps & Wildlife'), findsOneWidget);
      expect(find.text('Bad Bolt / Anchor'), findsOneWidget);
      expect(find.text('Other Danger'), findsOneWidget);
    });

    testWidgets('ReportHazardFormScreen renders outdoor crag and form elements', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cragsProvider.overrideWith((ref) => Future.value([mockOutdoorCrag])),
          ],
          child: const MaterialApp(
            home: ReportHazardFormScreen(),
          ),
        ),
      );

      expect(find.text('HAZARD DETAILS'), findsOneWidget);
      expect(find.text('OUTDOOR CLIMBING CRAG *'), findsOneWidget);
      expect(find.text('Tap to select outdoor crag'), findsOneWidget);
      expect(find.text('ROUTE IN CRAG'), findsOneWidget);
      expect(find.text('SEVERITY LEVEL'), findsOneWidget);
      expect(find.text('DESCRIPTION & PRECAUTIONS *'), findsOneWidget);
      expect(find.text('SUBMIT HAZARD REPORT'), findsOneWidget);
    });

    testWidgets('VenuePickerBottomSheet outdoorOnly filters out indoor gyms and shows route dropdown',
        (tester) async {
      Crag? pickedCrag;
      String? pickedRoute;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: VenuePickerBottomSheet(
                title: 'Select Outdoor Crag',
                venues: const [mockOutdoorCrag, mockIndoorGym],
                selectedVenueId: null,
                outdoorOnly: true,
                onSelected: (crag) => pickedCrag = crag,
                onRouteSelected: (route) => pickedRoute = route?.name,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Outdoor crag must be visible
      expect(find.text('Batu Caves'), findsOneWidget);
      // Indoor gym must be filtered out
      expect(find.text('Camp5 1 Utama'), findsNothing);

      // Tap Batu Caves -> reveals route dropdown in the bottom sheet
      await tester.tap(find.text('Batu Caves'));
      await tester.pumpAndSettle();

      expect(find.text('Route in Batu Caves:'), findsOneWidget);
      expect(find.byKey(const Key('crag_route_dropdown')), findsOneWidget);

      // Tap Confirm
      final confirmBtn = find.text('SELECT CRAG (ALL ROUTES)');
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(pickedCrag?.name, 'Batu Caves');
      expect(pickedRoute, isNull);
    });

    testWidgets('ReportConfirmationScreen renders success badge and actions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ReportConfirmationScreen(),
          ),
        ),
      );

      expect(find.text('Hazard Reported!'), findsOneWidget);
      expect(find.text('ACTIVE ALERT'), findsOneWidget);
      expect(find.text('BACK TO CRAGS'), findsOneWidget);
      expect(find.text('VIEW ON MAP'), findsOneWidget);
    });
  });

  group('Hazard Report End-to-End Navigation Flow', () {
    testWidgets('Tapping Report Hazard button navigates through 3-page flow to confirmation',
        (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cragsProvider.overrideWith((ref) => Future.value([mockOutdoorCrag, mockIndoorGym])),
            recentRoutesProvider.overrideWith((ref) => Future.value([])),
            hazardAlertsProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const ClimbMYApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Initial State: On HomeScreen (Crags tab), FAB is present
      final reportFab = find.byType(ReportHazardButton);
      expect(reportFab, findsOneWidget);

      // 2. Tap Report Hazard FAB -> navigates to SelectHazardTypeScreen
      await tester.tap(reportFab);
      await tester.pumpAndSettle();

      expect(find.text('Select Hazard Type'), findsOneWidget);
      expect(find.text('Loose Rock'), findsOneWidget);

      // 3. Tap 'Loose Rock' category -> navigates to ReportHazardFormScreen
      await tester.tap(find.text('Loose Rock'));
      await tester.pumpAndSettle();

      expect(find.text('HAZARD DETAILS'), findsOneWidget);
      expect(find.text('Selected Category'), findsOneWidget);

      // 4. Attempt submitting without crag or description -> shows validation SnackBar
      final submitBtn = find.text('SUBMIT HAZARD REPORT');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();
      expect(find.text('Please select an outdoor climbing crag first.'), findsOneWidget);
      await tester.pumpAndSettle();

      // 5. Select Outdoor Crag via picker
      await tester.ensureVisible(find.text('Tap to select outdoor crag'));
      await tester.tap(find.text('Tap to select outdoor crag'));
      await tester.pumpAndSettle();

      // In picker bottom sheet, outdoor crag exists while indoor gym does not
      expect(find.text('Select Outdoor Crag'), findsOneWidget);
      expect(find.text('Batu Caves'), findsOneWidget);
      expect(find.text('Camp5 1 Utama'), findsNothing);

      await tester.tap(find.text('Batu Caves'));
      await tester.pumpAndSettle();

      // Tap confirm in bottom sheet
      await tester.tap(find.text('SELECT CRAG (ALL ROUTES)'));
      await tester.pumpAndSettle();

      expect(find.text('Batu Caves'), findsOneWidget);

      // 6. Route Dropdown on form is now active for Batu Caves
      expect(find.byKey(const Key('report_form_route_dropdown')), findsOneWidget);

      // 7. Enter description
      final descriptionField = find.byKey(const Key('hazard_description_field'));
      await tester.ensureVisible(descriptionField);
      await tester.enterText(
        descriptionField,
        'Flake detached near 3rd bolt on Banana Jam, high rockfall risk.',
      );
      await tester.pumpAndSettle();

      // 8. Submit form -> navigates to ReportConfirmationScreen
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Hazard Reported!'), findsOneWidget);
      expect(find.text('BACK TO CRAGS'), findsOneWidget);

      // 9. Tap 'BACK TO CRAGS' -> returns to HomeScreen
      await tester.tap(find.text('BACK TO CRAGS'));
      await tester.pumpAndSettle();

      expect(find.text('Popular Crags'), findsOneWidget);
      expect(find.byType(ReportHazardButton), findsOneWidget);
    });
  });
}
