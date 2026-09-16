import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crag.dart';
import '../models/route_item.dart';
import '../models/hazard_alert.dart';

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

