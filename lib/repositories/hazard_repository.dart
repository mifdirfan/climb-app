import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/hazard_alert.dart';
import '../providers/supabase_provider.dart';

final hazardRepositoryProvider = Provider<HazardRepository>((ref) {
  return HazardRepository(ref.watch(supabaseClientProvider));
});

class HazardRepository {
  final SupabaseClient _client;
  HazardRepository(this._client);

  Future<List<HazardAlert>> getActiveAlerts() async {
    try {
      debugPrint('--> [HAZARDS:REPO] Fetching recent active hazard alerts');
      final response = await _client
          .from('hazard_alerts')
          .select('*, sectors(name), routes(name)')
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(5);
      return (response as List<dynamic>)
          .map((item) => HazardAlert.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('--> [HAZARDS:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    }
  }
}