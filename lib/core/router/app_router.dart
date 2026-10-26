import 'package:climbmy/screens/indoor_log_screen.dart';
import 'package:climbmy/screens/indoor_log_daily.dart';
import 'package:climbmy/models/indoor_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/mainscreen/HomeScreen.dart';
import '../../screens/mainscreen/MapScreen.dart';
import '../../screens/mainscreen/PostScreen.dart';
import '../../screens/mainscreen/ProfileScreen.dart';
import '../../screens/hazard_report/select_hazard_type_screen.dart';
import '../../screens/hazard_report/report_hazard_form_screen.dart';
import '../../screens/hazard_report/report_confirmation_screen.dart';
import '../../screens/crags_list_screen.dart';
import '../../models/crag.dart';
import '../../models/route.dart';
import '../../screens/crag_detail_screen.dart';
import '../../screens/route_detail_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/report_hazard_button.dart';

/// Global navigator keys for the root GoRouter and individual shell branches.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorCragsKey = GlobalKey<NavigatorState>(debugLabel: 'shellCrags');
final _shellNavigatorMapKey = GlobalKey<NavigatorState>(debugLabel: 'shellMap');
final _shellNavigatorTicksKey = GlobalKey<NavigatorState>(debugLabel: 'shellTicks');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

/// Route path constants for ClimbApp.
class AppRoutes {
  static const String crags = '/crags';
  static const String map = '/map';
  static const String ticks = '/ticks';
  static const String profile = '/profile';
  static const String reportHazardSelect = '/report-hazard/select';
  static const String reportHazardForm = '/report-hazard/form';
  static const String reportHazardConfirmation = '/report-hazard/confirmation';
  static const String tickHistory = '/profile/tick-history';
  static const String savedCrags = '/profile/saved-crags';
  static const String indoorLog = '/profile/indoor-log';
  static const String indoorLogDaily = '/profile/indoor-log/daily';
  static const String cragDetail = '/crag/:id';
  static const String routeDetail = '/route/:id';
  static const String login = '/login';

  static String cragDetailPath(String id) => '/crag/$id';
  static String routeDetailPath(String id) => '/route/$id';
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
            navigatorKey: _shellNavigatorCragsKey,
            routes: [
              GoRoute(
                path: AppRoutes.crags,
                name: 'crags',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1: Interactive Map (MapScreen)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMapKey,
            routes: [
              GoRoute(
                path: AppRoutes.map,
                name: 'map',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const MapScreen(),
                ),
              ),
            ],
          ),

          // Branch 2: Ticks / Send Logger (PostScreen)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorTicksKey,
            routes: [
              GoRoute(
                path: AppRoutes.ticks,
                name: 'ticks',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const PostScreen(),
                ),
              ),
            ],
          ),

          // Branch 3: Profile & Logbook (ProfileScreen)
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Top-level Hazard Reporting routes (hiding bottom navigation bar)
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.reportHazardSelect,
        name: 'report-hazard-select',
        builder: (context, state) => const SelectHazardTypeScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.reportHazardForm,
        name: 'report-hazard-form',
        builder: (context, state) => const ReportHazardFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.reportHazardConfirmation,
        name: 'report-hazard-confirmation',
        builder: (context, state) => const ReportConfirmationScreen(),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.tickHistory,
        name: 'tick-history',
        builder: (context, state) => const VenuesListScreen(
          title: 'Tick History & Send Log',
          subtitle: 'Completed routes, redpoints, and flashes',
          emptyMessage: 'No ticks or sends logged yet',
          emptySubtitle: 'Log your sends in the Ticks tab to build your climbing logbook!',
          emptyIcon: Icons.history_rounded,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.savedCrags,
        name: 'saved-crags',
        builder: (context, state) => const VenuesListScreen(
          title: 'Saved Crags & Topos',
          subtitle: 'Cached sectors and topo guides for offline climbing',
          emptyMessage: 'No saved crags or topos yet',
          emptySubtitle: 'Explore crags on the Home or Map tab to save them for offline access!',
          emptyIcon: Icons.bookmark_border_rounded,
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.indoorLog, 
        name: 'indoor-log', 
        builder: (context, state) => const IndoorLogCalendarScreen(),
      ),   
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.indoorLogDaily,
        name: 'indoor-log-daily',
        builder: (context, state) {
          final extra = state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null;
          final date = extra?['date'] is DateTime
              ? extra!['date'] as DateTime
              : (extra?['date'] is String
                  ? DateTime.tryParse(extra!['date'] as String) ?? DateTime.now()
                  : DateTime.now());
          final rawSessions = extra?['sessions'];
          final List<IndoorSession> sessions = [];
          if (rawSessions is List) {
            for (final item in rawSessions) {
              if (item is IndoorSession) {
                sessions.add(item);
              } else if (item is Map) {
                try {
                  sessions.add(
                    IndoorSession.fromJson(Map<String, dynamic>.from(item)),
                  );
                } catch (e) {
                  debugPrint('[AppRouter] Failed to parse IndoorSession: $e');
                }
              }
            }
          }
          return DailyIndoorLogScreen(
            date: date,
            sessions: sessions,
          );
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.cragDetail,
        name: 'crag-detail',
        builder: (context, state) {
          final cragId = state.pathParameters['id'] ?? '';
          Crag? initialCrag;
          if (state.extra is Crag) {
            initialCrag = state.extra as Crag;
          } else if (state.extra is Map) {
            try {
              initialCrag = Crag.fromJson(Map<String, dynamic>.from(state.extra as Map));
            } catch (e) {
              debugPrint('[AppRouter] Failed to parse Crag from state.extra: $e');
            }
          }
          return CragDetailScreen(cragId: cragId, initialCrag: initialCrag);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.routeDetail,
        name: 'route-detail',
        builder: (context, state) {
          final routeId = state.pathParameters['id'] ?? '';
          RouteItem? initialRoute;
          if (state.extra is RouteItem) {
            initialRoute = state.extra as RouteItem;
          } else if (state.extra is Map) {
            try {
              initialRoute = RouteItem.fromJson(Map<String, dynamic>.from(state.extra as Map));
            } catch (e) {
              debugPrint('[AppRouter] Failed to parse RouteItem from state.extra: $e');
            }
          }
          return RouteDetailScreen(routeId: routeId, initialRoute: initialRoute);
        },
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) {
          final isSignUp = state.uri.queryParameters['mode'] == 'signup';
          final redirect = state.uri.queryParameters['redirect'];
          return LoginScreen(
            initialIsSignUp: isSignUp,
            redirectPath: redirect,
          );
        },
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
              onPressed: () => context.push(AppRoutes.reportHazardSelect),
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
