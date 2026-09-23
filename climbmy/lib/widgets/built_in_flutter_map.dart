import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/crag.dart';

/// Interactive built-in Flutter map widget with coordinate-projected venue pins,
/// smooth pinch-to-zoom/pan navigation, topographic contour aesthetics, and theme awareness.
class BuiltInFlutterMap extends StatefulWidget {
  final List<Crag> venues;
  final Crag? selectedVenue;
  final ValueChanged<Crag>? onVenueSelected;
  final VoidCallback? onTapBackground;
  final TransformationController? transformationController;
  final bool isTopographic;

  // Approximate Malaysia bounding box for coordinate projection
  static const double minLat = 1.2;
  static const double maxLat = 6.8;
  static const double minLng = 99.8;
  static const double maxLng = 104.5;

  // Virtual canvas dimensions for the interactive map
  static const double canvasWidth = 1000.0;
  static const double canvasHeight = 1200.0;

  /// Helper to convert GPS latitude and longitude to virtual canvas pixels.
  static (double, double) coordinatesToCanvas(double lat, double lng) {
    final normX = ((lng - minLng) / (maxLng - minLng)).clamp(0.08, 0.92);
    final normY = (1.0 - ((lat - minLat) / (maxLat - minLat))).clamp(0.08, 0.92);
    return (normX * canvasWidth, normY * canvasHeight);
  }

  const BuiltInFlutterMap({
    super.key,
    required this.venues,
    this.selectedVenue,
    this.onVenueSelected,
    this.onTapBackground,
    this.transformationController,
    this.isTopographic = true,
  });

  @override
  State<BuiltInFlutterMap> createState() => _BuiltInFlutterMapState();
}

class _BuiltInFlutterMapState extends State<BuiltInFlutterMap> {
  late final TransformationController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.transformationController != null) {
      _controller = widget.transformationController!;
    } else {
      _controller = TransformationController();
      _isInternalController = true;
    }
  }

  @override
  void dispose() {
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTap: widget.onTapBackground,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: InteractiveViewer(
              transformationController: _controller,
              boundaryMargin: const EdgeInsets.all(500),
              minScale: 0.5,
              maxScale: 3.5,
              constrained: false,
              child: SizedBox(
                width: BuiltInFlutterMap.canvasWidth,
                height: BuiltInFlutterMap.canvasHeight,
                child: Stack(
                  children: [
                    // 1. Topographic map background painter
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BuiltInMapPainter(
                          surfaceColor: theme.cardTheme.color ?? colorScheme.surface,
                          outlineColor: colorScheme.outlineVariant,
                          accentColor: colorScheme.primary,
                          isTopographic: widget.isTopographic,
                        ),
                      ),
                    ),

                    // 2. Interactive Venue Pins projected from GPS coordinates
                    ...widget.venues.map((venue) {
                      final coords = venue.coordinates;
                      final lat = coords.$1;
                      final lng = coords.$2;

                      // Normalize to canvas coordinates
                      final normX = ((lng - BuiltInFlutterMap.minLng) /
                              (BuiltInFlutterMap.maxLng - BuiltInFlutterMap.minLng))
                          .clamp(0.08, 0.92);
                      final normY = (1.0 -
                              ((lat - BuiltInFlutterMap.minLat) /
                                  (BuiltInFlutterMap.maxLat - BuiltInFlutterMap.minLat)))
                          .clamp(0.08, 0.92);

                      final posX = normX * BuiltInFlutterMap.canvasWidth;
                      final posY = normY * BuiltInFlutterMap.canvasHeight;
                      final isSelected = widget.selectedVenue?.id == venue.id;

                      final pinColor = venue.isIndoor
                          ? colorScheme.secondary
                          : colorScheme.primary;

                      return Positioned(
                        left: posX - 28,
                        top: posY - 52,
                        child: GestureDetector(
                          key: Key('venue_pin_${venue.id}'),
                          onTap: () => widget.onVenueSelected?.call(venue),
                          child: AnimatedScale(
                            scale: isSelected ? 1.25 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Pin Marker Badge
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? pinColor
                                        : (theme.cardTheme.color ?? colorScheme.surface),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : pinColor,
                                      width: isSelected ? 2.5 : 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? pinColor.withValues(alpha: 0.6)
                                            : Colors.black.withValues(alpha: 0.35),
                                        blurRadius: isSelected ? 12 : 6,
                                        offset: const Offset(0, 3),
                                        spreadRadius: isSelected ? 2 : 0,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    venue.isIndoor
                                        ? Icons.fitness_center_rounded
                                        : Icons.terrain_rounded,
                                    size: 18,
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : pinColor,
                                  ),
                                ),
                                const SizedBox(height: 3),

                                // Venue Name Label Chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.surfaceContainerHighest
                                        : Colors.black.withValues(alpha: 0.78),
                                    borderRadius: BorderRadius.circular(AppRadius.xs),
                                    border: Border.all(
                                      color: isSelected
                                          ? pinColor
                                          : colorScheme.outlineVariant.withValues(alpha: 0.4),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        venue.name,
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? colorScheme.onSurface
                                              : Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter rendering dark topographic contour aesthetics for Malaysia's climbing landscape.
class BuiltInMapPainter extends CustomPainter {
  final Color surfaceColor;
  final Color outlineColor;
  final Color accentColor;
  final bool isTopographic;

  BuiltInMapPainter({
    required this.surfaceColor,
    required this.outlineColor,
    required this.accentColor,
    this.isTopographic = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid Lines
    final gridPaint = Paint()
      ..color = outlineColor.withValues(alpha: 0.22)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const step = 48.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (isTopographic) {
      // 2. Topographic Mountain Elevation Contours (Titiwangsa, Batu Caves, Perlis, Johor)
      final contourPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.08)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      // Central massif: Batu Caves / Selangor limestone massifs
      final centerBatu = Offset(size.width * 0.40, size.height * 0.64);
      for (double r = 35; r < 240; r += 28) {
        canvas.drawCircle(centerBatu, r, contourPaint);
      }

      // Northern peaks: Bukit Keteri / Perlis limestone crags
      final centerPerlis = Offset(size.width * 0.16, size.height * 0.15);
      for (double r = 25; r < 180; r += 26) {
        canvas.drawCircle(centerPerlis, r, contourPaint);
      }

      // Perak / Ipoh karst towers
      final centerPerak = Offset(size.width * 0.32, size.height * 0.42);
      for (double r = 30; r < 190; r += 25) {
        canvas.drawCircle(centerPerak, r, contourPaint);
      }

      // Southern hills: Bukit Nyamuk / Gunung Ledang
      final centerJohor = Offset(size.width * 0.62, size.height * 0.82);
      for (double r = 25; r < 170; r += 28) {
        canvas.drawCircle(centerJohor, r, contourPaint);
      }

      // Kelantan limestone karst: Gua Musang
      final centerKelantan = Offset(size.width * 0.50, size.height * 0.38);
      for (double r = 30; r < 160; r += 26) {
        canvas.drawCircle(centerKelantan, r, contourPaint);
      }
    }

    // 3. Artistic Coordinate Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: "MALAYSIA TOPO CRAGS • 3°14'N 101°41'E",
        style: TextStyle(
          color: outlineColor.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(20, 20));
  }

  @override
  bool shouldRepaint(covariant BuiltInMapPainter oldDelegate) {
    return oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isTopographic != isTopographic;
  }
}
