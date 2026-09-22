// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/env_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart';
import '../../providers/home_providers.dart';
import '../../widgets/crag_map_card.dart';
import '../../widgets/map_legend.dart';

/// Screen displaying climbing crags geographically with interactive Google Maps by default,
/// floating Boulder and Gym legends, marker selection, and non-blocking async state handling.
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
  Crag? _selectedCrag;
  MapType _currentMapType = MapType.normal;
  VenueLegendFilter _legendFilter = VenueLegendFilter.all;

  // Default coordinate centered on West Malaysia climbing regions (Batu Caves / Selangor)
  static const LatLng _initialPosition = LatLng(3.2374, 101.6839);
  static const double _initialZoom = 8.0;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _animateToCrag(Crag crag) {
    setState(() {
      _selectedCrag = crag;
    });
    if (crag.parkingLat != null &&
        crag.parkingLong != null &&
        _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(crag.parkingLat!, crag.parkingLong!),
            zoom: 13.0,
          ),
        ),
      );
    }
  }

  void _resetCamera() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: _initialPosition,
            zoom: _initialZoom,
          ),
        ),
      );
    }
    setState(() {
      _selectedCrag = null;
    });
  }

  Set<Marker> _buildMarkers(List<Crag> crags) {
    final markers = <Marker>{};

    for (final crag in crags) {
      if (crag.parkingLat == null || crag.parkingLong == null) continue;

      // Filter based on selected legend filter
      if (_legendFilter == VenueLegendFilter.boulder && crag.isIndoor) continue;
      if (_legendFilter == VenueLegendFilter.gym && !crag.isIndoor) continue;

      final isSelected = _selectedCrag?.id == crag.id;
      markers.add(
        Marker(
          markerId: MarkerId(crag.id),
          position: LatLng(crag.parkingLat!, crag.parkingLong!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isSelected
                ? BitmapDescriptor.hueOrange
                : (crag.isIndoor
                    ? BitmapDescriptor.hueCyan
                    : BitmapDescriptor.hueRed),
          ),
          infoWindow: InfoWindow(
            title: crag.name,
            snippet: '${crag.routeCount} routes • ${crag.isIndoor ? "Gym" : "Boulder"}',
            onTap: () => _animateToCrag(crag),
          ),
          onTap: () {
            setState(() {
              _selectedCrag = crag;
            });
          },
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cragsAsync = ref.watch(cragsProvider);
    final allCrags = cragsAsync.value ?? const <Crag>[];
    final isLoading = cragsAsync.isLoading;
    final hasError = cragsAsync.hasError;

    final boulderCount = allCrags.where((c) => !c.isIndoor).length;
    final gymCount = allCrags.where((c) => c.isIndoor).length;

    // Filter crags according to selected legend filter
    final displayedCrags = allCrags.where((c) {
      if (_legendFilter == VenueLegendFilter.boulder) return !c.isIndoor;
      if (_legendFilter == VenueLegendFilter.gym) return c.isIndoor;
      return true;
    }).toList();

    final markers = _buildMarkers(displayedCrags);
    final hasValidKey = EnvConfig.hasValidGoogleMapsKey;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // No header / AppBar on MapScreen per user specification
      body: Stack(
        children: [
          // 1. Google Map widget displayed by default
          Positioned.fill(
            child: hasValidKey
                ? GoogleMap(
                    onMapCreated: _onMapCreated,
                    initialCameraPosition: const CameraPosition(
                      target: _initialPosition,
                      zoom: _initialZoom,
                    ),
                    markers: markers,
                    style: _darkMapStyle,
                    mapType: _currentMapType,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: true,
                    mapToolbarEnabled: false,
                    onTap: (_) {
                      setState(() {
                        _selectedCrag = null;
                      });
                    },
                  )
                : _buildPlaceholderMap(displayedCrags),
          ),

          // 2. Top Bar: Floating Back Button & Boulder / Gym Legends
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Row(
                children: [
                  // Floating Back Button
                  InkWell(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/crags');
                      }
                    },
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Legends of Boulder and Gym
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: MapLegend(
                        selectedFilter: _legendFilter,
                        onFilterChanged: (filter) {
                          setState(() {
                            _legendFilter = filter;
                          });
                        },
                        boulderCount: boulderCount,
                        gymCount: gymCount,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Map Controls (Right side: Pin count, Layer toggle, Re-center)
          Positioned(
            top: 76,
            right: 16,
            child: SafeArea(
              child: Column(
                children: [
                  // Venue count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${markers.length} crags',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Map Type Toggle Button (Normal <-> Terrain)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _currentMapType == MapType.terrain
                            ? Icons.layers_rounded
                            : Icons.terrain_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Toggle Terrain Layer',
                      onPressed: () {
                        setState(() {
                          _currentMapType = _currentMapType == MapType.normal
                              ? MapType.terrain
                              : MapType.normal;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Re-center Map Button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.my_location_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Re-center Map',
                      onPressed: _resetCamera,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Subtle Floating Loading Indicator (Non-blocking)
          if (isLoading)
            Positioned(
              top: 76,
              left: 16,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Updating crags...',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Floating Error Toast if crags failed to fetch
          if (hasError)
            Positioned(
              top: 76,
              left: 16,
              right: 80,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.hazardContainer.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.hazardText.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.hazardText,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error loading crag pins',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.hazardText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => ref.invalidate(cragsProvider),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: AppColors.hazardText,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Selected Crag Floating Preview Card (CragMapCard)
          if (_selectedCrag != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 80,
              child: CragMapCard(
                crag: _selectedCrag!,
                onClose: () {
                  setState(() {
                    _selectedCrag = null;
                  });
                },
                onTapDetails: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Text('Opening ${_selectedCrag!.name}...'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// High-fidelity visual topographic radar map placeholder used before an API key is supplied or in tests.
  Widget _buildPlaceholderMap(List<Crag> crags) {
    return Container(
      color: AppColors.background,
      child: Stack(
        children: [
          // Grid lines
          Positioned.fill(
            child: CustomPaint(
              painter: _MapTopographicPainter(),
            ),
          ),

          // Interactive mock pins representing the actual crags
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final validCrags = crags
                    .where((c) => c.parkingLat != null && c.parkingLong != null)
                    .toList();

                if (validCrags.isEmpty) {
                  return const SizedBox.shrink();
                }

                // Malaysia approximate bounding box for projection
                const minLat = 1.2;
                const maxLat = 6.8;
                const minLng = 99.8;
                const maxLng = 104.5;

                return Stack(
                  children: validCrags.map((crag) {
                    final lat = crag.parkingLat!;
                    final lng = crag.parkingLong!;

                    // Normalize to canvas coordinates
                    final normX =
                        ((lng - minLng) / (maxLng - minLng)).clamp(0.08, 0.92);
                    final normY = (1.0 - ((lat - minLat) / (maxLat - minLat)))
                        .clamp(0.08, 0.92);

                    final posX = normX * constraints.maxWidth;
                    final posY = normY * constraints.maxHeight;
                    final isSelected = _selectedCrag?.id == crag.id;

                    return Positioned(
                      left: posX - 18,
                      top: posY - 36,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCrag = crag;
                          });
                        },
                        child: AnimatedScale(
                          scale: isSelected ? 1.25 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.surfaceElevated,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: isSelected ? 2.0 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  crag.isIndoor
                                      ? Icons.fitness_center_rounded
                                      : Icons.terrain_rounded,
                                  size: 16,
                                  color: isSelected
                                      ? AppColors.onPrimary
                                      : AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  crag.name,
                                  style: AppTextStyles.caption.copyWith(
                                    fontSize: 9,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for dark topographic map aesthetics.
class _MapTopographicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.borderSubtle.withValues(alpha: 0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Topographic concentric contours
    final contourPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final center1 = Offset(size.width * 0.45, size.height * 0.4);
    for (double r = 40; r < 200; r += 32) {
      canvas.drawCircle(center1, r, contourPaint);
    }

    final center2 = Offset(size.width * 0.65, size.height * 0.65);
    for (double r = 30; r < 160; r += 28) {
      canvas.drawCircle(center2, r, contourPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dark map styling JSON matching ClimbApp's palette.
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#1c1b1b"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#d8c2b8"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#131313"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#53433c"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#a8a29e"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2a2a2a"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#111414"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#515c6d"}]
  }
]
''';
