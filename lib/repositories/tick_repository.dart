import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
}