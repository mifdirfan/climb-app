// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart';
import '../../providers/home_providers.dart';

/// Venue filter options for the map view
enum VenueTypeFilter {
  all,
  crags,
  gyms,
}

/// Map screen displaying interactive Google Map with:
/// - Pointers for each climbing gym and crag from Supabase
/// - Filter selecting between all, crags, or gyms
/// - Zoom in/out and My Location buttons
/// - Bottom sliding boulder list sheet
class MapScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const MapScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  VenueTypeFilter _selectedFilter = VenueTypeFilter.all;
  Crag? _selectedVenue;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(3.2374, 101.6839), // Central Batu Caves / Klang Valley climbing area
    zoom: 11.0,
  );

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onFilterSelected(VenueTypeFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _goToMyLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(3.2374, 101.6839),
          zoom: 13.5,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(List<Crag> venues, ThemeData theme) {
    final filteredVenues = venues.where((venue) {
      switch (_selectedFilter) {
        case VenueTypeFilter.all:
          return true;
        case VenueTypeFilter.crags:
          return venue.isOutdoor;
        case VenueTypeFilter.gyms:
          return venue.isIndoor;
      }
    }).toList();

    return filteredVenues.map((venue) {
      final coords = venue.coordinates;
      final isSelected = _selectedVenue?.id == venue.id;

      return Marker(
        markerId: MarkerId(venue.id),
        position: LatLng(coords.$1, coords.$2),
        infoWindow: InfoWindow(
          title: venue.name,
          snippet: '${venue.isIndoor ? "Indoor Gym" : "Outdoor Crag"} • ${venue.state}',
        ),
        icon: venue.isIndoor
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        zIndexInt: isSelected ? 10 : 1,
        onTap: () {
          setState(() {
            _selectedVenue = venue;
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(coords.$1, coords.$2)),
          );
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final venuesAsync = ref.watch(mapVenuesProvider);
    final venues = venuesAsync.asData?.value ?? defaultMapVenues;
    final markers = _buildMarkers(venues, theme);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Google Map filling the entire page
          Positioned.fill(
            child: GoogleMap(
              key: const Key('google_map'),
              initialCameraPosition: _initialCameraPosition,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              markers: markers,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),

          // 2. Top Floating Filter Bar (All / Crags / Gyms)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              bottom: false,
              child: Container(
                key: const Key('venue_filter_bar'),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? colorScheme.surface,
                  borderRadius: AppRadius.borderPill,
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _FilterSegment(
                      key: const Key('filter_all'),
                      label: 'All',
                      count: venues.length,
                      isSelected: _selectedFilter == VenueTypeFilter.all,
                      onTap: () => _onFilterSelected(VenueTypeFilter.all),
                    ),
                    const SizedBox(width: 4),
                    _FilterSegment(
                      key: const Key('filter_crags'),
                      label: 'Crags',
                      icon: Icons.terrain_outlined,
                      count: venues.where((v) => v.isOutdoor).length,
                      isSelected: _selectedFilter == VenueTypeFilter.crags,
                      onTap: () => _onFilterSelected(VenueTypeFilter.crags),
                    ),
                    const SizedBox(width: 4),
                    _FilterSegment(
                      key: const Key('filter_gyms'),
                      label: 'Gyms',
                      icon: Icons.fitness_center_outlined,
                      count: venues.where((v) => v.isIndoor).length,
                      isSelected: _selectedFilter == VenueTypeFilter.gyms,
                      onTap: () => _onFilterSelected(VenueTypeFilter.gyms),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Action Controls (Zoom In/Out & My Location)
          Positioned(
            right: 16,
            bottom: 210,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // My Location Button
                Material(
                  color: theme.cardTheme.color ?? colorScheme.surface,
                  borderRadius: AppRadius.borderSm,
                  elevation: 0,
                  child: InkWell(
                    key: const Key('my_location_button'),
                    onTap: _goToMyLocation,
                    borderRadius: AppRadius.borderSm,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: colorScheme.outlineVariant,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.my_location,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Zoom Controls Container
                Container(
                  key: const Key('zoom_controls_container'),
                  width: 44,
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? colorScheme.surface,
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        key: const Key('zoom_in_button'),
                        onTap: _zoomIn,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.sm),
                        ),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.add,
                            color: colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant,
                      ),
                      InkWell(
                        key: const Key('zoom_out_button'),
                        onTap: _zoomOut,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(AppRadius.sm),
                        ),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.remove,
                            color: colorScheme.onSurface,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Sliding Boulder List Sheet at the bottom
          DraggableScrollableSheet(
            key: const Key('boulder_list_sheet'),
            initialChildSize: 0.25,
            minChildSize: 0.12,
            maxChildSize: 0.85,
            snap: true,
            snapSizes: const [0.12, 0.25, 0.5, 0.85],
            builder: (context, scrollController) {
              return Container(
                key: const Key('boulder_sheet_container'),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg),
                  ),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: CustomScrollView(
                  key: const Key('boulder_list_scroll_view'),
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Drag handle
                    SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: colorScheme.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // If a venue is selected on the map, show its info banner
                          if (_selectedVenue != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedVenue!.name,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_selectedVenue!.isIndoor ? "Indoor Climbing Gym" : "Outdoor Crag"} • ${_selectedVenue!.state}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _selectedVenue!.isIndoor
                                          ? (colorScheme.secondaryContainer)
                                          : colorScheme.primaryContainer,
                                      borderRadius: AppRadius.borderXs,
                                    ),
                                    child: Text(
                                      _selectedVenue!.isIndoor ? 'GYM' : 'CRAG',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: _selectedVenue!.isIndoor
                                            ? (colorScheme.onSecondaryContainer)
                                            : colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    // Empty boulder list (no elements in the list yet)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const SizedBox.shrink(),
                        childCount: 0,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Internal segmented filter item widget for MapScreen top bar
class _FilterSegment extends StatelessWidget {
  final String label;
  final IconData? icon;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterSegment({
    super.key,
    required this.label,
    this.icon,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderPill,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: AppRadius.borderPill,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.onPrimary.withValues(alpha: 0.15)
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: AppRadius.borderPill,
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
