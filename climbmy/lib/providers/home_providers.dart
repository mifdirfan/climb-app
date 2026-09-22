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

/// Riverpod FutureProvider reading routes for a specific crag
final cragRoutesProvider =
    FutureProvider.family<List<RouteItem>, String>((ref, cragId) async {
  try {
    final response = await Supabase.instance.client
        .from('routes')
        .select('*, sectors!inner(id, name, crag_id)')
        .eq('sectors.crag_id', cragId)
        .order('name', ascending: true);

    final list = (response as List<dynamic>)
        .map((item) => RouteItem.fromJson(item as Map<String, dynamic>))
        .toList();

    if (list.isNotEmpty) return list;
  } catch (_) {
    // Fallback if table is unseeded or network is offline
  }

  String? cragName;
  try {
    final crags = await ref.watch(cragsProvider.future);
    cragName = crags.firstWhere((c) => c.id == cragId).name;
  } catch (_) {}

  return getFallbackRoutesForCrag(cragId, cragName);
});

/// Fallback catalog of climbing routes for known crags
List<RouteItem> getFallbackRoutesForCrag(String cragId, [String? cragName]) {
  final name = cragName?.toLowerCase() ?? '';
  final id = cragId.toLowerCase();

  if (name.contains('batu') || id.contains('batu') || id == 'crag-1') {
    return const [
      RouteItem(
        id: 'route-batu-1',
        sectorId: 'sector-damai',
        name: 'Banana Jam',
        grade: '6b+',
        routeType: 'sport',
        sectorName: 'Damai Wall',
        cragName: 'Batu Caves',
      ),
      RouteItem(
        id: 'route-batu-2',
        sectorId: 'sector-damai',
        name: 'The Grunt',
        grade: '7a',
        routeType: 'sport',
        sectorName: 'Damai Wall',
        cragName: 'Batu Caves',
      ),
      RouteItem(
        id: 'route-batu-3',
        sectorId: 'sector-white',
        name: 'White Wall Traverse',
        grade: '6c',
        routeType: 'sport',
        sectorName: 'White Wall',
        cragName: 'Batu Caves',
      ),
      RouteItem(
        id: 'route-batu-4',
        sectorId: 'sector-damai',
        name: 'Ape Escape',
        grade: '6a+',
        routeType: 'sport',
        sectorName: 'Damai Wall',
        cragName: 'Batu Caves',
      ),
    ];
  } else if (name.contains('keteri') || id.contains('keteri')) {
    return const [
      RouteItem(
        id: 'route-keteri-1',
        sectorId: 'sector-keteri-main',
        name: 'Starlight',
        grade: '7c',
        routeType: 'sport',
        sectorName: 'Main Cave',
        cragName: 'Bukit Keteri',
      ),
      RouteItem(
        id: 'route-keteri-2',
        sectorId: 'sector-keteri-main',
        name: 'Limestone Cowboy',
        grade: '6b',
        routeType: 'sport',
        sectorName: 'Main Cave',
        cragName: 'Bukit Keteri',
      ),
      RouteItem(
        id: 'route-keteri-3',
        sectorId: 'sector-keteri-roof',
        name: 'Caveman Roof',
        grade: '8a',
        routeType: 'sport',
        sectorName: 'The Roof',
        cragName: 'Bukit Keteri',
      ),
    ];
  } else if (name.contains('nyamuk') || id.contains('nyamuk')) {
    return const [
      RouteItem(
        id: 'route-nyamuk-1',
        sectorId: 'sector-nyamuk-1',
        name: 'Mosquito Bite',
        grade: '6a+',
        routeType: 'sport',
        sectorName: 'Left Sector',
        cragName: 'Bukit Nyamuk',
      ),
      RouteItem(
        id: 'route-nyamuk-2',
        sectorId: 'sector-nyamuk-1',
        name: 'Blood Donor',
        grade: '6c',
        routeType: 'sport',
        sectorName: 'Central Sector',
        cragName: 'Bukit Nyamuk',
      ),
    ];
  }

  return [
    RouteItem(
      id: 'route-$cragId-1',
      sectorId: 'sector-$cragId-1',
      name: 'Main Wall Classic',
      grade: '6a',
      routeType: 'sport',
      sectorName: 'Main Wall',
      cragName: cragName ?? 'Crag',
    ),
    RouteItem(
      id: 'route-$cragId-2',
      sectorId: 'sector-$cragId-1',
      name: 'Overhang Project',
      grade: '7a',
      routeType: 'sport',
      sectorName: 'Upper Tier',
      cragName: cragName ?? 'Crag',
    ),
  ];
}

/// Riverpod FutureProvider reading all venues (gyms & crags) for MapScreen
final mapVenuesProvider = FutureProvider<List<Crag>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('crags')
        .select()
        .order('name', ascending: true);

    final list = (response as List<dynamic>)
        .map((item) => Crag.fromJson(item as Map<String, dynamic>))
        .toList();

    if (list.isNotEmpty) return list;
  } catch (_) {
    // Graceful fallback for offline / mock / test environments
  }

  return defaultMapVenues;
});

/// Default catalog of climbing venues (outdoor crags and indoor climbing gyms) in Malaysia
const List<Crag> defaultMapVenues = [
  Crag(
    id: 'crag-batu-caves',
    name: 'Batu Caves (Damai Wall)',
    venueType: 'outdoor',
    state: 'Selangor',
    parkingLat: 3.2374,
    parkingLong: 101.6839,
    approachNotes: 'Park at Gua Damai Extreme Park.',
    routeCount: 42,
  ),
  Crag(
    id: 'crag-bukit-keteri',
    name: 'Bukit Keteri',
    venueType: 'outdoor',
    state: 'Perlis',
    parkingLat: 6.5312,
    parkingLong: 100.2588,
    approachNotes: 'Park near railway tracks, 10 min approach.',
    routeCount: 35,
  ),
  Crag(
    id: 'crag-bukit-nyamuk',
    name: 'Bukit Nyamuk',
    venueType: 'outdoor',
    state: 'Johor',
    parkingLat: 2.1833,
    parkingLong: 102.7667,
    approachNotes: 'Trailhead starts behind oil palm plantation.',
    routeCount: 18,
  ),
  Crag(
    id: 'crag-gua-musang',
    name: 'Gua Musang',
    venueType: 'outdoor',
    state: 'Kelantan',
    parkingLat: 4.8821,
    parkingLong: 101.9680,
    approachNotes: 'Limestone hill near town center.',
    routeCount: 24,
  ),
  Crag(
    id: 'gym-camp5-1u',
    name: 'Camp5 1 Utama',
    venueType: 'indoor',
    state: 'Selangor',
    address: '1 Utama Shopping Centre, Petaling Jaya',
    parkingLat: 3.1502,
    parkingLong: 101.6155,
    operatingHours: '10:00 AM - 10:00 PM',
  ),
  Crag(
    id: 'gym-camp5-eco-city',
    name: 'Camp5 KL Eco City',
    venueType: 'indoor',
    state: 'WP Kuala Lumpur',
    address: 'KL Eco City Mall, Bangsar',
    parkingLat: 3.1182,
    parkingLong: 101.6744,
    operatingHours: '10:00 AM - 10:00 PM',
  ),
  Crag(
    id: 'gym-bolder-bpm',
    name: 'Bolder bpm',
    venueType: 'indoor',
    state: 'Selangor',
    address: 'Subang Jaya Industrial Estate',
    parkingLat: 3.0733,
    parkingLong: 101.5901,
    operatingHours: '12:00 PM - 10:00 PM',
  ),
  Crag(
    id: 'gym-bump-bouldering',
    name: 'Bump Bouldering Jaya One',
    venueType: 'indoor',
    state: 'Selangor',
    address: 'Jaya One, Petaling Jaya',
    parkingLat: 3.1189,
    parkingLong: 101.6358,
    operatingHours: '12:00 PM - 10:30 PM',
  ),
  Crag(
    id: 'gym-project-rock',
    name: 'Project Rock Gurney',
    venueType: 'indoor',
    state: 'Penang',
    address: 'Gurney Plaza, George Town',
    parkingLat: 5.4371,
    parkingLong: 100.3097,
    operatingHours: '10:00 AM - 10:00 PM',
  ),
];



