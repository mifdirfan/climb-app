import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Test-controllable auth flag. `isAuthenticatedProvider` is overridden to
/// watch this, so a test can flip auth mid-test and assert reactive rebuilds
/// without touching Supabase.
class FakeAuthNotifier extends Notifier<bool> {
  FakeAuthNotifier(this._initial);
  final bool _initial;

  @override
  bool build() => _initial;

  void signIn() => state = true;
  void signOut() => state = false;
}

/// Handles returned by [pumpRouterApp] for assertions.
class RouterHarness {
  RouterHarness(this.router, this.container, this.fakeAuth);

  final GoRouter router;
  final ProviderContainer container;
  final NotifierProvider<FakeAuthNotifier, bool> fakeAuth;

  /// Every URI the stub login route was opened with, in order.
  final List<Uri> loginVisits = [];

  Uri? get lastLogin => loginVisits.isEmpty ? null : loginVisits.last;

  void signIn() => container.read(fakeAuth.notifier).signIn();
}

/// Text rendered by the stub login route.
const loginStubText = 'LOGIN_STUB';

/// Pumps [home] inside a real [GoRouter] + [ProviderScope].
///
/// - `/` renders [home] (or [initialLocation] if it matches an [extraRoutes] entry).
/// - [AppRoutes.login] is a stub that records its URI in [RouterHarness.loginVisits].
/// - `isAuthenticatedProvider` is driven by a [FakeAuthNotifier].
Future<RouterHarness> pumpRouterApp(
  WidgetTester tester, {
  required Widget home,
  bool isAuthenticated = false,
  String initialLocation = '/',
  List<RouteBase> extraRoutes = const [],
  List<Override> overrides = const [],
}) async {
  final fakeAuth = NotifierProvider<FakeAuthNotifier, bool>(
    () => FakeAuthNotifier(isAuthenticated),
  );
  late RouterHarness harness;

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, state) {
          harness.loginVisits.add(state.uri);
          return const Scaffold(body: Center(child: Text(loginStubText)));
        },
      ),
      ...extraRoutes,
    ],
  );

  final container = ProviderContainer(
    // Riverpod 3 auto-retries failed providers on a timer; disable so error
    // states render deterministically and no timers outlive the test.
    retry: (_, _) => null,
    overrides: [
      isAuthenticatedProvider.overrideWith((ref) => ref.watch(fakeAuth)),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  addTearDown(router.dispose);

  harness = RouterHarness(router, container, fakeAuth);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.darkTheme,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}
