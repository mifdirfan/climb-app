import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crag.dart';
import '../providers/supabase_provider.dart';

final savedCragRepositoryProvider = Provider<SavedCragRepository>((ref) {
  return SavedCragRepository(ref.watch(supabaseClientProvider));
});

/// Data access for per-user crag bookmarks (`public.saved_crags`).
///
/// Bookmarks live in their own join table (rather than an array column on
/// `profiles`) so RLS can scope rows to their owner and the crag join stays a
/// single PostgREST embed.
class SavedCragRepository {
  final SupabaseClient _client;
  SavedCragRepository(this._client);

  /// Postgres unique_violation: the bookmark already exists.
  static const _uniqueViolation = '23505';

  /// Returns [userId]'s saved crags, most recently saved first.
  ///
  /// @source PostgreSQL:saved_crags ⨝ crags
  /// @sink   In-memory `List<Crag>`
  Future<List<Crag>> getSavedCrags(String userId) async {
    try {
      debugPrint('--> [SAVED_CRAGS:REPO] Fetching saved crags for UID: $userId');
      final response = await _client
          .from('saved_crags')
          .select('created_at, crags(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final crags = (response as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['crags'])
          .whereType<Map<String, dynamic>>() // drops rows whose crag was deleted
          .map(Crag.fromJson)
          .toList();
      debugPrint('--> [SAVED_CRAGS:REPO] Resolved ${crags.length} saved crags');
      return crags;
    } on PostgrestException catch (e) {
      debugPrint('--> [SAVED_CRAGS:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } on AuthException catch (e) {
      debugPrint('--> [SAVED_CRAGS:REPO] AuthException: ${e.message}');
      throw Exception('Authentication error: ${e.message}');
    }
  }

  /// Bookmarks [cragId] for [userId]. Idempotent: an existing bookmark is a no-op.
  ///
  /// @source App: CragDetailScreen bookmark toggle
  /// @sink   PostgreSQL:saved_crags (INSERT)
  Future<void> saveCrag({required String userId, required String cragId}) async {
    try {
      debugPrint('--> [SAVED_CRAGS:REPO] Saving crag $cragId');
      await _client.from('saved_crags').insert({'user_id': userId, 'crag_id': cragId});
    } on PostgrestException catch (e) {
      if (e.code == _uniqueViolation) {
        debugPrint('--> [SAVED_CRAGS:REPO] Crag $cragId already saved; ignoring');
        return;
      }
      debugPrint('--> [SAVED_CRAGS:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } on AuthException catch (e) {
      debugPrint('--> [SAVED_CRAGS:REPO] AuthException: ${e.message}');
      throw Exception('Authentication error: ${e.message}');
    }
  }

  /// Removes [userId]'s bookmark of [cragId] (no-op if absent).
  ///
  /// @source App: CragDetailScreen bookmark toggle
  /// @sink   PostgreSQL:saved_crags (DELETE)
  Future<void> unsaveCrag({required String userId, required String cragId}) async {
    try {
      debugPrint('--> [SAVED_CRAGS:REPO] Removing saved crag $cragId');
      await _client
          .from('saved_crags')
          .delete()
          .eq('user_id', userId)
          .eq('crag_id', cragId);
    } on PostgrestException catch (e) {
      debugPrint('--> [SAVED_CRAGS:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } on AuthException catch (e) {
      debugPrint('--> [SAVED_CRAGS:REPO] AuthException: ${e.message}');
      throw Exception('Authentication error: ${e.message}');
    }
  }
}
