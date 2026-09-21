import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/mainscreen/HomeScreen.dart';
import '../../screens/mainscreen/MapScreen.dart';
import '../../screens/mainscreen/PostScreen.dart';
import '../../screens/mainscreen/ProfileScreen.dart';
import '../../widgets/floating_bottom_nav_bar.dart';
import '../../widgets/report_hazard_button.dart';

/// Global navigator key for the root GoRouter.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Route path constants for ClimbApp.
class AppRoutes {
  static const String crags = '/crags';
  static const String map = '/map';
  static const String ticks = '/ticks';
  static const String profile = '/profile';
}

/// Riverpod provider exposing the application-wide GoRouter instance.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.crags,
    debugLogDiagnostics: false,
    routes: [
      // Top-level redirect from root to /crags
      GoRoute(
        path: '/',
        redirect: (context, state) => AppRoutes.crags,
      ),

      // StatefulShellRoute maintains tab state, scroll positions, and hosts FloatingBottomNavBar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Crags / Guidebook (HomeScreen)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.crags,
                name: 'crags',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Interactive Map (MapScreen)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.map,
                name: 'map',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: MapScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: Ticks / Send Logger (PostScreen)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.ticks,
                name: 'ticks',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PostScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Profile & Logbook (ProfileScreen)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Shell widget wrapping all bottom navigation destinations with the
/// floating navigation bar and contextual actions.
class MainScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainScaffold({
    super.key,
    required this.navigationShell,
  });

  void _onTabTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHomeTab = navigationShell.currentIndex == 0;

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: navigationShell,
      // Contextual Report Hazard FAB shown on Crags tab
      floatingActionButton: isHomeTab
          ? ReportHazardButton(
              onPressed: () => ReportHazardButton.showReportModal(context),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: FloatingBottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}
