import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crag.dart';
import '../providers/supabase_provider.dart';

final cragRepositoryProvider = Provider<CragRepository>((ref) {
  return CragRepository(ref.watch(supabaseClientProvider));
});

class CragRepository {
  final SupabaseClient _client;
  CragRepository(this._client);

  Future<List<Crag>> getCrags({required String stateFilter, required String searchQuery}) async {
    try {
      debugPrint('--> [CRAGS:REPO] Fetching crags (State: $stateFilter, Query: $searchQuery)');
      var query = _client.from('crags').select();
      
      if (stateFilter != 'All') {
        query = query.ilike('state', stateFilter);
      }
      
      final response = await query.order('created_at', ascending: false);
      final list = (response as List<dynamic>)
          .map((item) => Crag.fromJson(item as Map<String, dynamic>))
          .toList();

      if (searchQuery.isNotEmpty) {
        return list.where((crag) => 
          crag.name.toLowerCase().contains(searchQuery) ||
          crag.state.toLowerCase().contains(searchQuery)
        ).toList();
      }
      return list;
    } on PostgrestException catch (e) {
      debugPrint('--> [CRAGS:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    }
  }

  Future<Crag?> getCragById(String id) async {
    try {
      debugPrint('--> [CRAGS:REPO] Fetching crag detail for ID: $id');
      final response = await _client.from('crags').select().eq('id', id).maybeSingle();
      if (response == null) return null;
      return Crag.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('--> [CRAGS:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    }
  }

  Future<List<Crag>> getAllVenues() async {
    try {
      debugPrint('--> [VENUES:REPO] Fetching all venues from public.crags');
      final response = await _client.from('crags').select().order('name', ascending: true);
      final venues = (response as List<dynamic>)
          .map((item) => Crag.fromJson(item as Map<String, dynamic>))
          .toList();
      debugPrint('--> [VENUES:REPO] Successfully mapped ${venues.length} venues');
      return venues;
    } on PostgrestException catch (e) {
      debugPrint('--> [VENUES:REPO] PostgrestException: ${e.message}');
      throw Exception('Database error: ${e.message}');
    }
  }
}