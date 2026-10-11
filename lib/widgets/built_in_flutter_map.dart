import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import '../models/crag.dart';

class BuiltInFlutterMap extends StatefulWidget {
  final List<Crag> venues;
  final Crag? selectedVenue;
  final ValueChanged<Crag>? onVenueSelected;
  final VoidCallback? onTapBackground;
  final MapController? mapController;
  final ValueChanged<LatLngBounds>? onVisibleBoundsChanged;

  const BuiltInFlutterMap({
    super.key,
    required this.venues,
    this.selectedVenue,
    this.onVenueSelected,
    this.onTapBackground,
    this.mapController,
    this.onVisibleBoundsChanged,
  });

  @override
  State<BuiltInFlutterMap> createState() => _BuiltInFlutterMapState();
}

class _BuiltInFlutterMapState extends State<BuiltInFlutterMap> {
  late final MapController _mapController;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.mapController != null) {
      _mapController = widget.mapController!;
    } else {
      _mapController = MapController();
      _isInternalController = true;
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _mapController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(3.15, 101.65),
        initialZoom: 11.5,
        minZoom: 5.0,
        maxZoom: 18.0,
        onTap: (tapPosition, point) => widget.onTapBackground?.call(),
        onMapReady: () {
          widget.onVisibleBoundsChanged?.call(_mapController.camera.visibleBounds);
        },
        onPositionChanged: (camera, hasGesture) {
          widget.onVisibleBoundsChanged?.call(camera.visibleBounds);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.climbmy',
          retinaMode: RetinaMode.isHighDensity(context),
          tileProvider: CancellableNetworkTileProvider(),
        ),

        // Interactive Venue Markers
        MarkerLayer(
          markers: widget.venues.map((venue) {
            final coords = venue.coordinates;
            final lat = coords.$1;
            final lng = coords.$2;
            final isSelected = widget.selectedVenue?.id == venue.id;

            final pinColor = venue.isIndoor
                ? colorScheme.secondary
                : colorScheme.primary;

            return Marker(
              point: LatLng(lat, lng),
              width: 160,
              height: 70,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                key: Key('venue_pin_${venue.id}'),
                onTap: () => widget.onVenueSelected?.call(venue),
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? pinColor
                              : (theme.cardTheme.color ?? colorScheme.surface),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : pinColor,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? pinColor.withValues(alpha: 0.6)
                                  : Colors.black.withValues(alpha: 0.4),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          venue.isIndoor
                              ? Icons.fitness_center_rounded
                              : Icons.terrain_rounded,
                          size: 18,
                          color: isSelected ? colorScheme.onPrimary : pinColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}