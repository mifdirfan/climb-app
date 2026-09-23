import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/models/crag.dart';
import 'package:climbmy/providers/home_providers.dart';
import 'package:climbmy/screens/mainscreen/ProfileScreen.dart';
import 'package:climbmy/screens/crags_list_screen.dart';

void main() {
  final testVenues = [
    const Crag(
      id: 'crag-batu-caves',
      name: 'Batu Caves',
      venueType: 'outdoor',
      state: 'Selangor',
      routeCount: 42,
    ),
    const Crag(
      id: 'crag-bukit-keteri',
      name: 'Bukit Keteri',
      venueType: 'outdoor',
      state: 'Perlis',
      routeCount: 35,
    ),
    const Crag(
      id: 'gym-camp5-1u',
      name: 'Camp5 1 Utama',
      venueType: 'indoor',
      state: 'Selangor',
      address: '1 Utama Shopping Centre',
      operatingHours: '10:00 AM - 10:00 PM',
      routeCount: 150,
    ),
  ];

  Widget buildTestWidget({
    VoidCallback? onEditProfile,
    VoidCallback? onShareProfile,
  }) {
    final testRouter = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => ProfileScreen(
            onEditProfile: onEditProfile,
            onShareProfile: onShareProfile,
          ),
        ),
        GoRoute(
          path: AppRoutes.tickHistory,
          builder: (context, state) => const VenuesListScreen(
            title: 'Tick History & Send Log',
            subtitle: 'Completed routes, redpoints, and flashes',
            emptyMessage: 'No ticks or sends logged yet',
            emptySubtitle: 'Log your sends in the Ticks tab to build your climbing logbook!',
            emptyIcon: Icons.history_rounded,
          ),
        ),
        GoRoute(
          path: AppRoutes.savedCrags,
          builder: (context, state) => const VenuesListScreen(
            title: 'Saved Crags & Topos',
            subtitle: 'Cached sectors and topo guides for offline climbing',
            emptyMessage: 'No saved crags or topos yet',
            emptySubtitle: 'Explore crags on the Home or Map tab to save them for offline access!',
            emptyIcon: Icons.bookmark_border_rounded,
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        mapVenuesProvider.overrideWith((ref) => Future.value(testVenues)),
      ],
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        routerConfig: testRouter,
      ),
    );
  }

  group('ProfileScreen & VenuesListScreen Tests (GoRouter)', () {
    testWidgets('Renders ProfileScreen with Edit Profile and Share Profile buttons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Profile header and user info
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Malaysian Climber'), findsOneWidget);
      expect(find.text('Outdoor Sport & Boulder Enthusiast'), findsOneWidget);

      // Edit Profile & Share Profile buttons
      final editBtn = find.byKey(const Key('edit_profile_button'));
      final shareBtn = find.byKey(const Key('share_profile_button'));
      expect(editBtn, findsOneWidget);
      expect(shareBtn, findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Share Profile'), findsOneWidget);

      // Stats boxes
      expect(find.text('POSTS'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('CRAGS VISITED'), findsOneWidget);

      // Menu options
      expect(find.text('Tick History & Send Log'), findsOneWidget);
      expect(find.text('Saved Crags & Topos'), findsOneWidget);
      expect(find.text('Indoor Climbing Log'), findsOneWidget);
    });

    testWidgets('Tapping Edit Profile and Share Profile triggers callbacks', (tester) async {
      bool editCalled = false;
      bool shareCalled = false;

      await tester.pumpWidget(
        buildTestWidget(
          onEditProfile: () => editCalled = true,
          onShareProfile: () => shareCalled = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('edit_profile_button')));
      await tester.pumpAndSettle();
      expect(editCalled, isTrue);

      await tester.tap(find.byKey(const Key('share_profile_button')));
      await tester.pumpAndSettle();
      expect(shareCalled, isTrue);
    });

    testWidgets('Tapping Tick History & Send Log pushes GoRoute /profile/tick-history', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Tick History & Send Log'
      await tester.tap(find.text('Tick History & Send Log'));
      await tester.pumpAndSettle();

      // VenuesListScreen is pushed via GoRouter
      expect(find.byType(VenuesListScreen), findsOneWidget);
      expect(find.text('Tick History & Send Log'), findsWidgets);

      // Search bar and filter tabs exist
      expect(find.byKey(const Key('venues_search_field')), findsOneWidget);
      expect(find.byKey(const Key('filter_all')), findsOneWidget);
      expect(find.byKey(const Key('filter_crags')), findsOneWidget);
      expect(find.byKey(const Key('filter_gyms')), findsOneWidget);

      // All places shown initially
      expect(find.text('Batu Caves'), findsOneWidget);
      expect(find.text('Bukit Keteri'), findsOneWidget);
      expect(find.text('Camp5 1 Utama'), findsOneWidget);

      // Tap Outdoor Crags filter
      await tester.tap(find.byKey(const Key('filter_crags')));
      await tester.pumpAndSettle();

      // Crags remain, Gyms filtered out
      expect(find.text('Batu Caves'), findsOneWidget);
      expect(find.text('Bukit Keteri'), findsOneWidget);
      expect(find.text('Camp5 1 Utama'), findsNothing);

      // Tap Climbing Gyms filter
      await tester.tap(find.byKey(const Key('filter_gyms')));
      await tester.pumpAndSettle();

      // Gyms remain, Crags filtered out
      expect(find.text('Camp5 1 Utama'), findsOneWidget);
      expect(find.text('Batu Caves'), findsNothing);
      expect(find.text('Bukit Keteri'), findsNothing);

      // Test Search query
      await tester.tap(find.byKey(const Key('filter_all')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('venues_search_field')), 'Keteri');
      await tester.pumpAndSettle();

      expect(find.text('Bukit Keteri'), findsOneWidget);
      expect(find.text('Batu Caves'), findsNothing);
      expect(find.text('Camp5 1 Utama'), findsNothing);

      // Pop back via GoRouter context.pop()
      await tester.tap(find.byKey(const Key('venues_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(VenuesListScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('Tapping Saved Crags & Topos pushes GoRoute /profile/saved-crags', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Saved Crags & Topos'
      await tester.tap(find.text('Saved Crags & Topos'));
      await tester.pumpAndSettle();

      expect(find.byType(VenuesListScreen), findsOneWidget);
      expect(find.text('Saved Crags & Topos'), findsWidgets);
      expect(find.text('Batu Caves'), findsOneWidget);

      // Pop back via GoRouter context.pop()
      await tester.tap(find.byKey(const Key('venues_back_button')));
      await tester.pumpAndSettle();

      expect(find.byType(VenuesListScreen), findsNothing);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });
  });
}
