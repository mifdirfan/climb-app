import 'package:climbmy/core/config/app_links.dart';
import 'package:climbmy/core/router/app_router.dart';
import 'package:climbmy/providers/app_info_providers.dart';
import 'package:climbmy/repositories/auth_repository.dart';
import 'package:climbmy/screens/settings/legal_content.dart';
import 'package:climbmy/screens/settings/legal_document_screen.dart';
import 'package:climbmy/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/pump_app.dart';

/// Records calls; never touches Supabase.
class FakeAuthRepository implements AuthRepository {
  int signOutCalls = 0;
  int deleteCalls = 0;
  Object? deleteError;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();
  @override
  Session? get currentSession => null;
  @override
  User? get currentUser => null;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  Future<void> deleteAccount() async {
    deleteCalls++;
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<AuthResponse> signIn({required String email, required String password}) =>
      throw UnimplementedError();
  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) =>
      throw UnimplementedError();
}

const _homeStub = 'HOME_STUB';
const _cragsStub = 'CRAGS_STUB';

void main() {
  late FakeAuthRepository repo;
  late List<Uri> launched;

  setUp(() {
    repo = FakeAuthRepository();
    launched = [];
  });

  /// Opens Settings on top of a stub "/" page, so `pop` and `go` are observable.
  Future<RouterHarness> pumpSettings(WidgetTester tester, {bool signedIn = false}) async {
    final harness = await pumpRouterApp(
      tester,
      home: const Scaffold(body: Text(_homeStub)),
      isAuthenticated: signedIn,
      extraRoutes: [
        GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsScreen()),
        GoRoute(
          path: AppRoutes.privacyPolicy,
          builder: (_, _) => const LegalDocumentScreen(document: privacyPolicy),
        ),
        GoRoute(
          path: AppRoutes.terms,
          builder: (_, _) => const LegalDocumentScreen(document: termsOfService),
        ),
        GoRoute(path: AppRoutes.crags, builder: (_, _) => const Scaffold(body: Text(_cragsStub))),
      ],
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        appVersionProvider.overrideWith((ref) async => '1.2.3 (45)'),
        externalLinkLauncherProvider.overrideWithValue((uri) async {
          launched.add(uri);
          return true;
        }),
      ],
    );
    harness.router.push(AppRoutes.settings);
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> tapTile(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).first);
    // scrollUntilVisible stops once *any* pixel shows; bring the whole row in.
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('layout', () {
    testWidgets('guest sees community, support, legal groups but no account group', (tester) async {
      await pumpSettings(tester);

      expect(find.text('COMMUNITY'), findsOneWidget);
      expect(find.text('SUPPORT'), findsOneWidget);
      expect(find.text('LEGAL'), findsOneWidget);
      expect(find.text('ACCOUNT'), findsNothing);
      expect(find.byKey(const Key('settings_sign_out')), findsNothing);
      expect(find.byKey(const Key('settings_delete_account')), findsNothing);
    });

    testWidgets('signed-in user also sees sign out and delete account', (tester) async {
      await pumpSettings(tester, signedIn: true);
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_delete_account')), 200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.byKey(const Key('settings_sign_out')), findsOneWidget);
    });

    testWidgets('footer shows app version and support email', (tester) async {
      await pumpSettings(tester);
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_version')), 200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('ClimbMY v1.2.3 (45)'), findsOneWidget);
      expect(find.text(AppLinks.supportEmail), findsOneWidget);
    });
  });

  group('legal pages', () {
    testWidgets('Privacy Policy opens the static privacy page', (tester) async {
      await pumpSettings(tester);
      await tapTile(tester, 'settings_privacy');
      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      expect(find.text(privacyPolicy.sections.first.heading), findsOneWidget);
    });

    testWidgets('Terms & Conditions opens the static terms page', (tester) async {
      await pumpSettings(tester);
      await tapTile(tester, 'settings_terms');
      expect(find.text(termsOfService.sections.first.heading), findsOneWidget);
    });
  });

  group('external links', () {
    testWidgets('Contact Us opens a mailto to support', (tester) async {
      await pumpSettings(tester);
      await tapTile(tester, 'settings_contact');
      expect(launched.single.scheme, 'mailto');
      expect(launched.single.path, AppLinks.supportEmail);
    });

    testWidgets('footer email also opens contact mailto', (tester) async {
      await pumpSettings(tester);
      await tapTile(tester, 'settings_footer_contact');
      expect(launched.single.path, AppLinks.supportEmail);
    });

    testWidgets('Report a Problem mailto includes the app version', (tester) async {
      await pumpSettings(tester);
      await tapTile(tester, 'settings_report');
      final uri = launched.single.toString();
      expect(uri, contains('problem%20report'));
      expect(uri, contains(Uri.encodeComponent('App version: 1.2.3 (45)')));
      expect(uri, isNot(contains('+')), reason: 'spaces must be %20, not +');
    });

    testWidgets('Discord shows SOON and does not launch while unset', (tester) async {
      await pumpSettings(tester);
      expect(find.text('SOON'), findsOneWidget);
      await tapTile(tester, 'settings_discord');
      expect(launched, isEmpty);
      expect(find.text('Our Discord is coming soon!'), findsOneWidget);
    });
  });

  group('account actions', () {
    testWidgets('Sign Out calls repository and returns to previous screen', (tester) async {
      await pumpSettings(tester, signedIn: true);
      await tapTile(tester, 'settings_sign_out');
      expect(repo.signOutCalls, 1);
      expect(find.text(_homeStub), findsOneWidget);
      expect(find.text('Logged out successfully.'), findsOneWidget);
    });

    testWidgets('Delete Account → Cancel does nothing', (tester) async {
      await pumpSettings(tester, signedIn: true);
      await tapTile(tester, 'settings_delete_account');
      expect(find.text('Delete account?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('delete_account_cancel')));
      await tester.pumpAndSettle();
      expect(repo.deleteCalls, 0);
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('Delete Account → Delete deletes and goes to crags', (tester) async {
      await pumpSettings(tester, signedIn: true);
      await tapTile(tester, 'settings_delete_account');
      await tester.tap(find.byKey(const Key('delete_account_confirm')));
      await tester.pumpAndSettle();

      expect(repo.deleteCalls, 1);
      expect(find.text(_cragsStub), findsOneWidget);
      expect(find.text('Your account has been deleted.'), findsOneWidget);
    });

    testWidgets('Delete Account failure stays on settings and shows the error', (tester) async {
      repo.deleteError = const PostgrestException(message: 'boom');
      await pumpSettings(tester, signedIn: true);
      await tapTile(tester, 'settings_delete_account');
      await tester.tap(find.byKey(const Key('delete_account_confirm')));
      await tester.pumpAndSettle();

      expect(repo.deleteCalls, 1);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Could not delete your account. Please try again.'), findsOneWidget);
    });
  });
}
