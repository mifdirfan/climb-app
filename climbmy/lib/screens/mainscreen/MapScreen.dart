// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart';
import '../../providers/home_providers.dart';
import '../../widgets/built_in_flutter_map.dart';
import '../../widgets/map_filter.dart';

/// Venue filter options for the map view
enum VenueTypeFilter {
  all,
  crags,
  gyms,
}

/// Map screen displaying interactive built-in Flutter Map with:
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

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _mapAnimation;

  VenueTypeFilter _selectedFilter = VenueTypeFilter.all;
  Crag? _selectedVenue;
  final bool _isTopographic = true;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..addListener(() {
        if (_mapAnimation != null) {
          _transformationController.value = _mapAnimation!.value;
        }
      });

    // Automatically center map on Central Malaysia / Batu Caves
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _goToMyLocation(animate: false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onFilterSelected(VenueTypeFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  void _animateMatrix(Matrix4 target) {
    _mapAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward(from: 0.0);
  }

  void _zoomIn() {
    final current = _transformationController.value;
    final size = MediaQuery.of(context).size;
    final focal = Offset(size.width / 2, size.height / 2);

    final target = Matrix4.copy(current)
        ..translateByDouble(focal.dx, focal.dy, 0.0, 1.0)
      ..scaleByDouble(1.25, 1.25, 1.0, 1.0)
      ..translateByDouble(-focal.dx, -focal.dy, 0.0, 1.0);

    _animateMatrix(target);
  }

  void _zoomOut() {
    final current = _transformationController.value;
    final size = MediaQuery.of(context).size;
    final focal = Offset(size.width / 2, size.height / 2);

    final target = Matrix4.copy(current)
      ..translateByDouble(focal.dx, focal.dy, 0.0, 1.0)
      ..scaleByDouble(0.8, 0.8, 1.0, 1.0)
      ..translateByDouble(-focal.dx, -focal.dy, 0.0, 1.0);

    _animateMatrix(target);
  }

  void _goToMyLocation({bool animate = true}) {
    // Batu Caves central climbing area coordinates: Lat 3.2374, Lng 101.6839
    final (canvasX, canvasY) =
        BuiltInFlutterMap.coordinatesToCanvas(3.2374, 101.6839);
    final size = MediaQuery.of(context).size;
    const scale = 1.15;

    final targetX = size.width / 2 - canvasX * scale;
    final targetY = size.height / 2 - canvasY * scale;

    final targetMatrix = Matrix4.identity()
      ..translateByDouble(targetX, targetY, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);

    if (animate) {
      _animateMatrix(targetMatrix);
    } else {
      _transformationController.value = targetMatrix;
    }
  }

  void _selectVenue(Crag venue) {
    setState(() {
      _selectedVenue = venue;
    });
    final coords = venue.coordinates;
    final (canvasX, canvasY) =
        BuiltInFlutterMap.coordinatesToCanvas(coords.$1, coords.$2);
    final size = MediaQuery.of(context).size;
    const scale = 1.4;

    final targetX = size.width / 2 - canvasX * scale;
    final targetY = size.height * 0.42 - canvasY * scale;

    final targetMatrix = Matrix4.identity()
      ..translateByDouble(targetX, targetY, 0.0, 1.0)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
   _animateMatrix(targetMatrix);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final venuesAsync = ref.watch(mapVenuesProvider);
    final allVenues = venuesAsync.asData?.value ?? defaultMapVenues;

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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Built-in Flutter Map filling the entire page
          Positioned.fill(
            child: BuiltInFlutterMap(
              key: const Key('built_in_flutter_map'),
              transformationController: _transformationController,
              venues: filteredVenues,
              selectedVenue: _selectedVenue,
              isTopographic: _isTopographic,
              onVenueSelected: _selectVenue,
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
                    onTap: () => _goToMyLocation(),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedVenue!.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${_selectedVenue!.isIndoor ? "Indoor Climbing Gym" : "Outdoor Crag"} • ${_selectedVenue!.state}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _selectedVenue!.isIndoor
                                          ? (colorScheme.secondaryContainer)
                                          : colorScheme.primaryContainer,
                                      borderRadius: AppRadius.borderXs,
                                    ),
                                    child: Text(
                                      _selectedVenue!.isIndoor
                                          ? 'GYM'
                                          : 'CRAG',
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: _selectedVenue!.isIndoor
                                            ? (colorScheme
                                                .onSecondaryContainer)
                                            : colorScheme
                                                .onPrimaryContainer,
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

                    // Empty boulder list
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