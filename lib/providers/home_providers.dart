import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crag.dart';
import '../models/route.dart';
import '../models/hazard_alert.dart';
import '../core/error/failures.dart';

/// Notifier for selected state filter ('All', 'Selangor', 'Perak', 'Perlis', 'Johor', etc.)
class SelectedStateFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setFilter(String stateName) {
    state = stateName;
  }
}

final selectedStateFilterProvider =
    NotifierProvider<SelectedStateFilterNotifier, String>(
  SelectedStateFilterNotifier.new,
);

/// Notifier for search bar text query
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Riverpod FutureProvider reading from public.crags
final cragsProvider = FutureProvider<List<Crag>>((ref) async {
  final selectedState = ref.watch(selectedStateFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();

  var query = Supabase.instance.client.from('crags').select();

  if (selectedState != 'All') {
    query = query.ilike('state', selectedState);
  }

  final response = await query.order('created_at', ascending: false);
  final list = (response as List<dynamic>)
      .map((item) => Crag.fromJson(item as Map<String, dynamic>))
      .toList();

  if (searchQuery.isNotEmpty) {
    return list.where((crag) {
      return crag.name.toLowerCase().contains(searchQuery) ||
          crag.state.toLowerCase().contains(searchQuery);
    }).toList();
  }

  return list;
});

/// Riverpod FutureProvider reading from public.routes
final recentRoutesProvider = FutureProvider<List<RouteItem>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('routes')
        .select('*, sectors(name, crags(name))')
        .order('created_at', ascending: false)
        .limit(10);

    final list = (response as List<dynamic>)
        .map((item) => RouteItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return list;
  } catch (e) {
    // If the table is not yet populated or relationships differ, return empty
    return [];
  }
});

/// Riverpod FutureProvider reading active alerts from public.hazard_alerts
final hazardAlertsProvider = FutureProvider<List<HazardAlert>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('hazard_alerts')
        .select('*, sectors(name), routes(name)')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(5);

    final list = (response as List<dynamic>)
        .map((item) => HazardAlert.fromJson(item as Map<String, dynamic>))
        .toList();

    return list;
  } catch (e) {
    // Fallback gracefully if table is empty or error occurs
    return [];
  }
});

/// Riverpod FutureProvider reading routes for a specific crag
final cragRoutesProvider =
    FutureProvider.family<List<RouteItem>, String>((ref, cragId) async {
  try {
    final response = await Supabase.instance.client
        .from('routes')
        .select('*, sectors!inner(id, name, crag_id)')
        .eq('sectors.crag_id', cragId)
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((item) => RouteItem.fromJson(item as Map<String, dynamic>))
        .toList();
  } on PostgrestException catch (e) {
    throw DatabaseFailure(e.message);
  } catch (_) {
    throw const NetworkFailure('Failed to load routes. Check your connection.');
  }
});

/// Riverpod FutureProvider reading a specific crag by ID
final cragDetailProvider =
    FutureProvider.family<Crag?, String>((ref, cragId) async {
  final response = await Supabase.instance.client
      .from('crags')
      .select()
      .eq('id', cragId)
      .maybeSingle();

  if (response == null) return null;
  return Crag.fromJson(response);
});

/// Riverpod FutureProvider reading a specific route by ID
final routeDetailProvider =
    FutureProvider.family<RouteItem?, String>((ref, routeId) async {
  final response = await Supabase.instance.client
      .from('routes')
      .select('*, sectors(*, crags(*))')
      .eq('id', routeId)
      .maybeSingle();

  if (response == null) return null;
  return RouteItem.fromJson(response);
});

/// Riverpod FutureProvider reading all venues (gyms & crags) for MapScreen
final mapVenuesProvider = FutureProvider<List<Crag>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('crags')
        .select()
        .order('name', ascending: true);

    return (response as List<dynamic>)
        .map((item) => Crag.fromJson(item as Map<String, dynamic>))
        .toList();
  } on PostgrestException catch (e) {
    throw DatabaseFailure(e.message);
  } catch (_) {
    throw const NetworkFailure('Unable to load climbing venues.');
  }
});




