import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/route.dart';
import '../providers/supabase_provider.dart';

final routeRepositoryProvider = Provider<RouteRepository>((ref) {
  return RouteRepository(ref.watch(supabaseClientProvider));
});

class RouteRepository {
  final SupabaseClient _client;
  RouteRepository(this._client);

  Future<List<RouteItem>> getRecentRoutes() async {
    try {
      debugPrint('--> [ROUTES:REPO] Fetching recent routes limit 10');
      final response = await _client
          .from('routes')
          .select('*, sectors(name, crags(name))')
          .order('created_at', ascending: false)
          .limit(10);
      return (response as List<dynamic>)
          .map((item) => RouteItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('--> [ROUTES:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    }
  }

  Future<List<RouteItem>> getRoutesByCrag(String cragId) async {
    try {
      debugPrint('--> [ROUTES:REPO] Fetching routes for crag: $cragId');
      final response = await _client
          .from('routes')
          .select('*, sectors!inner(id, name, crag_id)')
          .eq('sectors.crag_id', cragId)
          .order('name', ascending: true);
      return (response as List<dynamic>)
          .map((item) => RouteItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      debugPrint('--> [ROUTES:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    }
  }

  Future<RouteItem?> getRouteById(String id) async {
    try {
      debugPrint('--> [ROUTES:REPO] Fetching route detail for ID: $id');
      final response = await _client
          .from('routes')
          .select('*, sectors(*, crags(*))')
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return RouteItem.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('--> [ROUTES:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    }
  }
}