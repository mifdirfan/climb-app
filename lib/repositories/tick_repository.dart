import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/tick.dart';
import '../providers/supabase_provider.dart';

final tickRepositoryProvider = Provider<TickRepository>((ref) {
  return TickRepository(ref.watch(supabaseClientProvider));
});

class TickRepository {
  final SupabaseClient _client;
  TickRepository(this._client);

  Future<void> createTick(Map<String, dynamic> tickData) async {
    try {
      debugPrint('--> [TICKS:REPO] Submitting tick for routeId: ${tickData['route_id']}');
      await _client.from('ticks').insert(tickData);
      debugPrint('--> [TICKS:REPO] Tick submitted successfully');
    } on PostgrestException catch (e) {
      debugPrint('--> [TICKS:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('--> [TICKS:REPO] Unexpected error: $e');
      throw Exception('An unexpected error occurred while logging the tick.');
    }
  }

  /// Returns only [userId]'s ticks, newest climb first, with route, sector
  /// and crag names embedded for display.
  ///
  /// `public.ticks` is world-readable by RLS, so the `user_id` filter here is
  /// what scopes the logbook to the owner.
  ///
  /// @source PostgreSQL:ticks ⨝ routes ⨝ sectors / crags
  /// @sink   In-memory `List<Tick>`
  Future<List<Tick>> getTicksForUser(String userId) async {
    try {
      debugPrint('--> [TICKS:REPO] Fetching tick log for UID: $userId');
      final response = await _client
          .from('ticks')
          .select('*, routes(name, grade, route_type, crags(name), sectors(name))')
          .eq('user_id', userId)
          .order('climbed_at', ascending: false)
          .order('created_at', ascending: false);

      final ticks = (response as List<dynamic>)
          .map((row) => Tick.fromJson(row as Map<String, dynamic>))
          .toList();
      debugPrint('--> [TICKS:REPO] Resolved ${ticks.length} ticks');
      return ticks;
    } on PostgrestException catch (e) {
      debugPrint('--> [TICKS:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } on AuthException catch (e) {
      debugPrint('--> [TICKS:REPO] AuthException: ${e.message}');
      throw Exception('Authentication error: ${e.message}');
    }
  }
}
