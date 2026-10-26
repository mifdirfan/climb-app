import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crag.dart';
import '../models/route.dart';
import '../models/hazard_alert.dart';
import '../repositories/crag_repository.dart';
import '../repositories/route_repository.dart';
import '../repositories/hazard_repository.dart';
import '../core/error/failures.dart';

/// Notifier for selected state filter
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

/// Riverpod FutureProvider mapping to CragRepository
final cragsProvider = FutureProvider<List<Crag>>((ref) async {
  final selectedState = ref.watch(selectedStateFilterProvider);
  final searchQuery = ref.watch(searchQueryProvider).trim().toLowerCase();
  
  return ref.watch(cragRepositoryProvider).getCrags(
    stateFilter: selectedState, 
    searchQuery: searchQuery,
  );
});

/// Riverpod FutureProvider mapping to RouteRepository
final recentRoutesProvider = FutureProvider<List<RouteItem>>((ref) async {
  try {
    return await ref.watch(routeRepositoryProvider).getRecentRoutes();
  } catch (e) {
    return []; // Return empty list gracefully if table is empty
  }
});

/// Riverpod FutureProvider mapping to HazardRepository
final hazardAlertsProvider = FutureProvider<List<HazardAlert>>((ref) async {
  try {
    return await ref.watch(hazardRepositoryProvider).getActiveAlerts();
  } catch (e) {
    return [];
  }
});

/// Riverpod FutureProvider mapping to RouteRepository
final cragRoutesProvider =
    FutureProvider.family<List<RouteItem>, String>((ref, cragId) async {
  try {
    return await ref.watch(routeRepositoryProvider).getRoutesByCrag(cragId);
  } catch (e) {
    throw const NetworkFailure('Failed to load routes. Check your connection.');
  }
});

/// Riverpod FutureProvider mapping to CragRepository
final cragDetailProvider =
    FutureProvider.family<Crag?, String>((ref, cragId) async {
  return ref.watch(cragRepositoryProvider).getCragById(cragId);
});

/// Riverpod FutureProvider mapping to RouteRepository
final routeDetailProvider =
    FutureProvider.family<RouteItem?, String>((ref, routeId) async {
  return ref.watch(routeRepositoryProvider).getRouteById(routeId);
});

/// Riverpod FutureProvider reading all venues (gyms & crags) for MapScreen
final mapVenuesProvider = FutureProvider<List<Crag>>((ref) async {
  try {
    return await ref.watch(cragRepositoryProvider).getAllVenues();
  } catch (e) {
    throw const NetworkFailure('Unable to load climbing venues.');
  }
});