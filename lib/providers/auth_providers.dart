// lib/providers/auth_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

/// Stream listening to active session presence and auth events.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Exposes the currently authenticated Supabase User (or null if unauthenticated).
final currentUserProvider = Provider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  // 1. Reactive stream event
  final streamUser = authState.value?.session?.user;
  if (streamUser != null) return streamUser;

  // 2. Synchronous currentSession on client
  final sessionUser = repo.currentSession?.user;
  if (sessionUser != null) return sessionUser;

  // 3. Synchronous currentUser on client
  return repo.currentUser;
});

/// Returns true if the user has an active authenticated JWT session.
/// Synchronously checks both the reactive stream and the client's current session
/// to ensure privileges are granted immediately upon login redirect.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  // 1. Check reactive stream session
  final streamSession = authState.value?.session;
  if (streamSession != null && !streamSession.isExpired) {
    return true;
  }

  // 2. Synchronous client session check
  final clientSession = repo.currentSession;
  if (clientSession != null && !clientSession.isExpired) {
    return true;
  }

  // 3. Fallback check for authenticated user presence
  return repo.currentUser != null;
});

/// Controller handling sign in, sign up, and sign out requests.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider), ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthController(this._repository, this._ref) : super(const AsyncData(null));

  /// Authenticates user with email and password.
  ///
  /// - Intent: Signs in via Supabase and immediately invalidates auth state so privileges take effect.
  /// - @source: User email and password from LoginScreen.
  /// - @sink: Supabase GoTrue Auth service.
  /// - Side Effects: Sets active JWT in storage, forces re-evaluation of auth listeners.
  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    debugPrint('--> [AUTH:STATE] Transitioning state to AsyncLoading for sign in');
    try {
      final response = await _repository.signIn(email: email, password: password);
      debugPrint('--> [AUTH:STATE] Sign in success. User UID: ${response.user?.id}');
      debugPrint('    Session active: ${response.session != null}');

      // Invalidate stream provider to ensure immediate reactive sync across the widget tree
      _ref.invalidate(authStateProvider);
      state = const AsyncData(null);
      return true;
    } on AuthException catch (e, st) {
      debugPrint('--> [AUTH:STATE] 🛑 AuthException during signIn: ${e.message} (status: ${e.statusCode})');
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      debugPrint('--> [AUTH:STATE] 🛑 Unexpected error during signIn: $e\n$st');
      state = AsyncError('An unexpected error occurred.', st);
      return false;
    }
  }

  /// Registers a new user account with metadata for profile trigger.
  Future<bool> signUp(String email, String password, String username) async {
    state = const AsyncLoading();
    debugPrint('--> [AUTH:STATE] Transitioning state to AsyncLoading for sign up');
    try {
      final response = await _repository.signUp(
        email: email,
        password: password,
        username: username,
      );
      debugPrint('--> [AUTH:STATE] Sign up success. User UID: ${response.user?.id}');
      _ref.invalidate(authStateProvider);
      state = const AsyncData(null);
      return true;
    } on AuthException catch (e, st) {
      debugPrint('--> [AUTH:STATE] 🛑 AuthException during signUp: ${e.message} (status: ${e.statusCode})');
      state = AsyncError(e.message, st);
      return false;
    } catch (e, st) {
      debugPrint('--> [AUTH:STATE] 🛑 Unexpected error during signUp: $e\n$st');
      state = AsyncError('An unexpected error occurred.', st);
      return false;
    }
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() async {
    state = const AsyncLoading();
    debugPrint('--> [AUTH:STATE] Transitioning state to AsyncLoading for sign out');
    try {
      await _repository.signOut();
      _ref.invalidate(authStateProvider);
      state = const AsyncData(null);
      debugPrint('--> [AUTH:STATE] User successfully signed out');
    } catch (e, st) {
      debugPrint('--> [AUTH:STATE] 🛑 Error signing out: $e\n$st');
      state = AsyncError('Failed to sign out.', st);
    }
  }
}