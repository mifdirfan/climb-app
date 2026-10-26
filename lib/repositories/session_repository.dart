import 'package:climbmy/models/indoor_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/supabase_provider.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(supabaseClientProvider));
});

class SessionRepository {
  final SupabaseClient _client;
  SessionRepository(this._client);

  Future<void> createIndoorSession(Map<String, dynamic> sessionData) async {
    try {
      debugPrint('--> [SESSION:REPO] Submitting indoor session for gym: ${sessionData['gym_id']}');
      await _client.from('indoor_sessions').insert(sessionData);
      debugPrint('--> [SESSION:REPO] Indoor session submitted successfully');
    } on PostgrestException catch (e) {
      debugPrint('--> [SESSION:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint('--> [SESSION:REPO] Unexpected error: $e');
      throw Exception('An unexpected error occurred while logging the session.');
    }
  }
  
  Future<List<IndoorSession>> getMonthlySessions(String userId, DateTime month) async {
    try {
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final response = await _client
          .from('indoor_sessions')
          .select('*, crags(name)')
          .eq('user_id', userId)
          .gte('session_date', start.toIso8601String())
          .lte('session_date', end.toIso8601String());

      return (response as List<dynamic>)
          .map((item) => IndoorSession.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    }
  }
}