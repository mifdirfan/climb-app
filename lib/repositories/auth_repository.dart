import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

/// Encapsulates direct Supabase GoTrue authentication interactions.
class AuthRepository {
  final SupabaseClient _client;
  AuthRepository(this._client);

  /// Emits whenever user signs in, signs out, or token refreshes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Current active Supabase session (synchronous from client memory).
  Session? get currentSession => _client.auth.currentSession;

  /// Current authenticated Supabase user (synchronous from client memory).
  User? get currentUser => _client.auth.currentUser;

  /// Signs in an existing user using email and password.
  ///
  /// - @source: User credentials from AuthController.
  /// - @sink: Supabase GoTrue /token endpoint.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('--> [AUTH:REPO] signIn initiated for email: ${email.trim()}');
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    debugPrint('--> [AUTH:REPO] signIn completed: UID=${response.user?.id}, session=${response.session != null}');
    return response;
  }

  /// Registers a new user and passes initial metadata for profile trigger.
  ///
  /// - @source: Registration credentials from AuthController.
  /// - @sink: Supabase GoTrue signup endpoint.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    debugPrint('--> [AUTH:REPO] signUp initiated for email: ${email.trim()}, username: ${username.trim()}');
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'username': username.trim()},
    );
    debugPrint('--> [AUTH:REPO] signUp completed: UID=${response.user?.id}');
    return response;
  }

  /// Signs out of the current active session.
  Future<void> signOut() async {
    debugPrint('--> [AUTH:REPO] signOut initiated');
    await _client.auth.signOut();
    debugPrint('--> [AUTH:REPO] signOut completed');
  }
}