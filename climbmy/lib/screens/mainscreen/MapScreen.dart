// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart';
import '../../providers/home_providers.dart';
import '../../widgets/built_in_flutter_map.dart';
import '../../widgets/map_filter.dart';
import '../../widgets/visible_places_sheet.dart';

/// Venue filter options for the map view
enum VenueTypeFilter {
  all,
  crags,
  gyms,
}

class MapScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const MapScreen({
    super.key,
    this.onBack,
  });

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _animationController;
  VoidCallback? _activeAnimationListener;

  VenueTypeFilter _selectedFilter = VenueTypeFilter.all;
  Crag? _selectedVenue;
  LatLngBounds? _visibleBounds;

  // Central Batu Caves climbing coordinates
  static const LatLng _defaultLocation = LatLng(3.2374, 101.6839);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    if (_activeAnimationListener != null) {
      _animationController.removeListener(_activeAnimationListener!);
    }
    _animationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onFilterSelected(VenueTypeFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _onVisibleBoundsChanged(LatLngBounds bounds) {
    if (_visibleBounds != bounds) {
      setState(() {
        _visibleBounds = bounds;
      });
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // 1. Stop active animation and remove previous listeners
    _animationController.stop();
    if (_activeAnimationListener != null) {
      _animationController.removeListener(_activeAnimationListener!);
      _activeAnimationListener = null;
    }
    _animationController.reset();

    // 2. Set up tweens from current camera position
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    final curved = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );

    // 3. Define and attach single active listener
    _activeAnimationListener = () {
      _mapController.move(
        LatLng(latTween.evaluate(curved), lngTween.evaluate(curved)),
        zoomTween.evaluate(curved),
      );
    };

    _animationController.addListener(_activeAnimationListener!);

    // 4. Cleanup when animation completes
    _animationController.forward().then((_) {
      if (_activeAnimationListener != null) {
        _animationController.removeListener(_activeAnimationListener!);
        _activeAnimationListener = null;
      }
    });
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _animatedMapMove(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _animatedMapMove(_mapController.camera.center, currentZoom - 1.0);
  }

  void _goToMyLocation() {
    _animatedMapMove(_defaultLocation, 13.0);
  }

  void _selectVenue(Crag venue) {
    setState(() {
      _selectedVenue = venue;
    });

    final coords = venue.coordinates;
    // Offset slightly southward so the pin stays visible above the bottom sheet
    final targetLat = coords.$1 - 0.008;
    final targetLng = coords.$2;

    _animatedMapMove(LatLng(targetLat, targetLng), 14.5);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final venuesAsync = ref.watch(mapVenuesProvider);
    final List<Crag> allVenues = venuesAsync.maybeWhen(
      data: (venues) => venues,
      orElse: () => <Crag>[],
    );

    final filteredVenues = allVenues.where((venue) {
      switch (_selectedFilter) {
        case VenueTypeFilter.all:
          return true;
        case VenueTypeFilter.crags:
          return venue.isOutdoor;
        case VenueTypeFilter.gyms:
          return venue.isIndoor;
      }
    }).toList();

    // Venues currently visible in the map's viewport
    final visibleVenues = filteredVenues.where((venue) {
      if (_visibleBounds == null) return true;
      final coords = venue.coordinates;
      return _visibleBounds!.contains(LatLng(coords.$1, coords.$2));
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Built-in Flutter Map filling the entire page
          Positioned.fill(
            child: BuiltInFlutterMap(
              key: const Key('built_in_flutter_map'),
              mapController: _mapController,
              venues: filteredVenues,
              selectedVenue: _selectedVenue,
              onVenueSelected: _selectVenue,
              onVisibleBoundsChanged: _onVisibleBoundsChanged,
              onTapBackground: () {
                setState(() {
                  _selectedVenue = null;
                });
              },
            ),
          ),

          // 2. Top Floating Filter Bar (All / Crags / Gyms)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Center(
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MapFilter(
                        key: const Key('filter_all'),
                        label: 'All',
                        count: allVenues.length,
                        isSelected: _selectedFilter == VenueTypeFilter.all,
                        onTap: () => _onFilterSelected(VenueTypeFilter.all),
                      ),
                      const SizedBox(width: 4),
                      MapFilter(
                        key: const Key('filter_crags'),
                        label: 'Crags',
                        icon: Icons.terrain_outlined,
                        count: allVenues.where((v) => v.isOutdoor).length,
                        isSelected: _selectedFilter == VenueTypeFilter.crags,
                        onTap: () => _onFilterSelected(VenueTypeFilter.crags),
                      ),
                      const SizedBox(width: 4),
                      MapFilter(
                        key: const Key('filter_gyms'),
                        label: 'Gyms',
                        icon: Icons.fitness_center_outlined,
                        count: allVenues.where((v) => v.isIndoor).length,
                        isSelected: _selectedFilter == VenueTypeFilter.gyms,
                        onTap: () => _onFilterSelected(VenueTypeFilter.gyms),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Floating Action Controls (Zoom In/Out & My Location)
          Positioned(
            right: 16,
            bottom: 145,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

          // 4. Sliding Visible Places Sheet at the bottom
          VisiblePlacesSheet(
            venues: visibleVenues,
            selectedVenue: _selectedVenue,
            onVenueTap: (venue) {
              // Clickable venue element; no action performed yet as requested
            },
          ),
        ],
      ),
    );
  }
}