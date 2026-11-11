import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../models/crag.dart';
import '../models/hazard_alert.dart';
import '../models/route.dart';
import '../providers/home_providers.dart';
import '../providers/logbook_providers.dart';
import '../util/auth_guard.dart';
import '../util/grade_utils.dart';
import '../widgets/grade_chip.dart';
import '../widgets/hazard_alert_banner.dart';
import '../providers/hazard_report_providers.dart';

/// Available sorting modes for the route directory in CragDetailScreen.
enum CragRouteSort {
  gradeHardToEasy,
  gradeEasyToHard,
  nameAscending,
}

/// Screen displaying Crag or Gym Details matching model [Crag].
/// Dynamically differentiates between Indoor gyms and Outdoor crags:
/// - Indoor: displays address, operating hours, phone, instagram, and custom grading scale.
/// - Outdoor: displays approach notes, access restrictions, parking coordinates, and offline topo guide.
/// Only elements present in Supabase are rendered (null or empty fields are excluded).
class CragDetailScreen extends ConsumerStatefulWidget {
  final String cragId;
  final Crag? initialCrag;

  const CragDetailScreen({
    super.key,
    required this.cragId,
    this.initialCrag,
  });

  @override
  ConsumerState<CragDetailScreen> createState() => _CragDetailScreenState();
}

class _CragDetailScreenState extends ConsumerState<CragDetailScreen> {
  late final TextEditingController _searchController;
  String _selectedSector = 'ALL SECTORS';
  String _searchQuery = '';
  CragRouteSort _sortOption = CragRouteSort.gradeHardToEasy;
  /// Local-only flag for the (not yet implemented) offline topo download.
  /// Distinct from bookmarking, which persists via [savedCragsProvider].
  bool _isOfflineTopoCached = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.crags);
    }
  }

  /// Persists the bookmark via [SavedCragsNotifier] (optimistic, rolls back on error).
  Future<void> _toggleSaved(Crag crag) async {
    debugPrint('--> [SAVED_CRAGS:UI] Bookmark tapped for ${crag.id}');
    // Resolve everything context-dependent before the await (async-gap safe).
    final messenger = ScaffoldMessenger.of(context);
    final palette = context.palette;
    final snackStyle = context.textStyles.bodySmall.copyWith(color: palette.textPrimary);
    try {
      final nowSaved = await ref.read(savedCragsProvider.notifier).toggle(crag);
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: palette.surfaceElevated,
          content: Text(
            nowSaved ? '${crag.name} saved to your crags' : '${crag.name} removed from saved crags',
            style: snackStyle,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: palette.surfaceElevated,
          content: Text(
            'Could not update saved crags. Please try again.',
            style: snackStyle,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cragAsync = ref.watch(cragDetailProvider(widget.cragId));
    final routesAsync = ref.watch(cragRoutesProvider(widget.cragId));
    final hazardsAsync = ref.watch(cragHazardsProvider(widget.cragId));

    // Resolve crag entity without mock data
    final crag = cragAsync.value ?? widget.initialCrag;

    if (crag == null) {
      if (cragAsync.isLoading) {
        return Scaffold(
          backgroundColor: context.palette.background,
          appBar: AppBar(
            backgroundColor: context.palette.surface,
            elevation: 0,
            leading: IconButton(
              key: const Key('crag_back_button'),
              icon: Icon(Icons.arrow_back_rounded, color: context.palette.textPrimary),
              onPressed: _onBack,
            ),
          ),
          body: Center(
            child: CircularProgressIndicator(color: context.palette.accent),
          ),
        );
      }

      return Scaffold(
        backgroundColor: context.palette.background,
        appBar: AppBar(
          backgroundColor: context.palette.surface,
          elevation: 0,
          leading: IconButton(
            key: const Key('crag_back_button'),
            icon: Icon(Icons.arrow_back_rounded, color: context.palette.textPrimary),
            onPressed: _onBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: context.palette.hazardText),
                const SizedBox(height: 12),
                Text(
                  'Venue Not Found',
                  style: context.textStyles.titleMedium.copyWith(color: context.palette.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Could not locate venue records in Supabase.',
                  style: context.textStyles.caption.copyWith(color: context.palette.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(cragDetailProvider(widget.cragId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isIndoor = crag.isIndoor;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('crag_back_button'),
          icon: Icon(Icons.arrow_back_rounded, color: context.palette.textPrimary),
          onPressed: _onBack,
        ),
        title: Text(
          isIndoor ? 'GYM' : 'CRAG',
          style: context.textStyles.labelLarge.copyWith(
            color: context.palette.accent,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        actions: [
          if (!isIndoor)
            Builder(builder: (context) {
              final isSaved = ref.watch(isCragSavedProvider(crag.id));
              return IconButton(
                key: const Key('save_crag_button'),
                tooltip: isSaved ? 'Remove from saved crags' : 'Save crag',
                icon: Icon(
                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: isSaved ? context.palette.accent : context.palette.textSecondary,
                ),
                onPressed: () => requireAuth(
                  context,
                  ref,
                  action: () => _toggleSaved(crag),
                ),
              );
            }),
        ],
      ),
      body: routesAsync.when(
        data: (routes) => _buildContent(theme, crag, routes, hazardsAsync.value ?? []),
        loading: () => Center(
          child: CircularProgressIndicator(color: context.palette.accent),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded, size: 48, color: context.palette.hazardText),
                const SizedBox(height: 12),
                Text('Error loading routes', style: context.textStyles.titleMedium),
                const SizedBox(height: 8),
                Text('$err', style: context.textStyles.caption, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(cragRoutesProvider(widget.cragId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    ThemeData theme,
    Crag crag,
    List<RouteItem> routes,
    List<HazardAlert> hazards,
  ) {
    // Collect distinct sectors and count routes per sector dynamically from DB
    final Map<String, int> sectorCounts = {};
    for (final r in routes) {
      if (r.sectorName != null && r.sectorName!.isNotEmpty) {
        final s = r.sectorName!;
        sectorCounts[s] = (sectorCounts[s] ?? 0) + 1;
      }
    }
    final sectors = sectorCounts.keys.toList();

    // Filter routes by sector and search query
    var filteredRoutes = routes.where((r) {
      if (_selectedSector != 'ALL SECTORS') {
        final s = (r.sectorName != null && r.sectorName!.isNotEmpty)
            ? r.sectorName!
            : '';
        if (s.toLowerCase() != _selectedSector.toLowerCase()) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = r.name.toLowerCase().contains(q);
        final gradeMatch = r.grade.toLowerCase().contains(q);
        final typeMatch = r.routeType.toLowerCase().contains(q);
        return nameMatch || gradeMatch || typeMatch;
      }
      return true;
    }).toList();

    // Sort routes
    switch (_sortOption) {
      case CragRouteSort.gradeHardToEasy:
        filteredRoutes.sort((a, b) => gradeToScore(b.grade).compareTo(gradeToScore(a.grade)));
        break;
      case CragRouteSort.gradeEasyToHard:
        filteredRoutes.sort((a, b) => gradeToScore(a.grade).compareTo(gradeToScore(b.grade)));
        break;
      case CragRouteSort.nameAscending:
        filteredRoutes.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Active Safety Hazard Alerts Banner (if active hazards exist in Supabase)
          if (hazards.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: HazardAlertBanner(
                alert: hazards.first,
                customMessage: hazards.length > 1
                    ? '${hazards.length} ACTIVE ALERTS: ${hazards.map((h) => h.description).take(2).join(' • ')}'
                    : null,
                onTap: () {
                  if (hazards.first.routeId != null && hazards.first.routeId!.isNotEmpty) {
                    context.push(AppRoutes.routeDetailPath(hazards.first.routeId!));
                  }
                },
              ),
            ),

          // 2. Hero Section (Image, Name, State, Type, Styles)
          _buildHeroSection(crag, routes.length),

          // 3. Conditional Venue Details: Indoor vs Outdoor (strictly from Supabase fields)
          if (crag.isIndoor)
            _buildIndoorDetails(crag)
          else ...[
            _buildOutdoorDetails(crag, sectors.length),

            const SizedBox(height: 12),

            // 4. Sector Horizontal Selector (only for outdoor crags with multiple sectors)
            if (sectorCounts.length > 1) ...[
              _buildSectorSelector(sectors, routes.length, sectorCounts),
              const SizedBox(height: 16),
            ],

            // 5. Route Directory Header & Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildRouteDirectoryHeader(filteredRoutes.length, crag),
            ),

            const SizedBox(height: 12),

            // 6. Route Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('crag_routes_search_field'),
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: context.textStyles.bodyMedium.copyWith(color: context.palette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Filter by name, grade, or style...',
                  prefixIcon: Icon(Icons.search, size: 20, color: context.palette.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: context.palette.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 7. Sorting Selector Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildSortBar(),
            ),

            const SizedBox(height: 16),

            // 8. Route Directory List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildRouteList(filteredRoutes),
            ),
          ],

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Crag crag, int routeCount) {
    final count = routeCount > 0 ? routeCount : crag.routeCount;
    final typeLabel = crag.isIndoor ? 'INDOOR GYM' : 'OUTDOOR CRAG';
    final countSuffix = (!crag.isIndoor && count > 0) ? ' • $count ROUTES' : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.palette.surface,
        border: Border(
          bottom: BorderSide(color: context.palette.border, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image Frame with Dark Scrim
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                color: context.palette.surfaceElevated,
                child: crag.imageUrl != null && crag.imageUrl!.isNotEmpty
                    ? Image.network(
                        crag.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildHeroPlaceholder(crag.isIndoor),
                      )
                    : _buildHeroPlaceholder(crag.isIndoor),
              ),
              // Solid dark scrim for text readability (no gradients)
              Container(
                height: 200,
                width: double.infinity,
                color: context.palette.shadow.withValues(alpha: 0.45),
              ),
              // Subtitle & Heading over Image
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.palette.background.withValues(alpha: 0.85),
                        borderRadius: AppRadius.borderXs,
                      ),
                      child: Text(
                        '${crag.state.toUpperCase()}, MALAYSIA • $typeLabel$countSuffix',
                        style: context.textStyles.labelSmall.copyWith(
                          color: context.palette.accent,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      crag.name,
                      style: context.textStyles.headlineMedium.copyWith(
                        color: context.palette.onImage,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (crag.styles.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: crag.styles.map((style) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.palette.surfaceElevated.withValues(alpha: 0.9),
                              borderRadius: AppRadius.borderXs,
                              border: Border.all(color: context.palette.border, width: 0.8),
                            ),
                            child: Text(
                              style.toUpperCase(),
                              style: context.textStyles.caption.copyWith(
                                color: context.palette.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Outdoor-specific details: approach notes, access restrictions, parking coordinates, offline topo.
  /// If an attribute is null or empty in Supabase, it is NOT rendered.
  Widget _buildOutdoorDetails(Crag crag, int sectorCount) {
    final hasApproach = crag.approachNotes != null && crag.approachNotes!.isNotEmpty;
    final hasAccess = crag.accessRestrictions != null && crag.accessRestrictions!.isNotEmpty;
    final hasParking = crag.parkingLat != null && crag.parkingLong != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Approach Notes (if present)
          if (hasApproach)
            _buildDetailCard(
              icon: Icons.directions_walk_rounded,
              title: 'APPROACH NOTES',
              content: crag.approachNotes!,
            ),

          // Access Restrictions (if present)
          if (hasAccess) ...[
            if (hasApproach) const SizedBox(height: 10),
            _buildDetailCard(
              icon: Icons.info_outline_rounded,
              title: 'ACCESS & RESTRICTIONS',
              content: crag.accessRestrictions!,
              isAlert: true,
            ),
          ],

          // Parking Coordinates (if present)
          if (hasParking) ...[
            if (hasApproach || hasAccess) const SizedBox(height: 10),
            _buildParkingCard(crag.parkingLat!, crag.parkingLong!),
          ],

          // Offline Topo Download Action Button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('offline_topo_button'),
              onPressed: () {
                setState(() => _isOfflineTopoCached = !_isOfflineTopoCached);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: context.palette.surfaceElevated,
                    content: Text(
                      _isOfflineTopoCached
                          ? '${crag.name} offline topo guide cached'
                          : '${crag.name} offline topo guide removed',
                      style: context.textStyles.bodySmall.copyWith(color: context.palette.textPrimary),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                _isOfflineTopoCached ? Icons.check_circle_rounded : Icons.file_download_outlined,
                size: 18,
                color: _isOfflineTopoCached ? context.palette.accent : context.palette.textPrimary,
              ),
              label: Text(
                _isOfflineTopoCached ? 'OFFLINE TOPO DOWNLOADED' : 'DOWNLOAD OFFLINE TOPO',
                style: context.textStyles.labelMedium.copyWith(
                  color: _isOfflineTopoCached ? context.palette.accent : context.palette.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _isOfflineTopoCached ? context.palette.accent : context.palette.border,
                  width: 1.0,
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Indoor-specific details: address, operating hours, phone, instagram, custom grading scale.
  /// If an attribute is null or empty in Supabase, it is NOT rendered.
  Widget _buildIndoorDetails(Crag crag) {
    final hasAddress = crag.address != null && crag.address!.isNotEmpty;
    final hasHours = crag.operatingHours != null && crag.operatingHours!.isNotEmpty;
    final hasPhone = crag.phone != null && crag.phone!.isNotEmpty;
    final hasInstagram = crag.instagram != null && crag.instagram!.isNotEmpty;
    final hasGradingScale = crag.gradingScale.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address (if present)
          if (hasAddress)
            _buildDetailCard(
              icon: Icons.location_on_outlined,
              title: 'ADDRESS',
              content: crag.address!,
            ),

          // Operating Hours (if present)
          if (hasHours) ...[
            if (hasAddress) const SizedBox(height: 10),
            _buildDetailCard(
              icon: Icons.access_time_rounded,
              title: 'OPERATING HOURS',
              content: crag.operatingHours!,
            ),
          ],

          // Contact Row: Phone & Instagram (if present)
          if (hasPhone || hasInstagram) ...[
            if (hasAddress || hasHours) const SizedBox(height: 10),
            Row(
              children: [
                if (hasPhone)
                  Expanded(
                    child: _buildContactChip(
                      icon: Icons.phone_outlined,
                      label: crag.phone!,
                    ),
                  ),
                if (hasPhone && hasInstagram) const SizedBox(width: 10),
                if (hasInstagram)
                  Expanded(
                    child: _buildContactChip(
                      icon: Icons.camera_alt_outlined,
                      label: crag.instagram!.startsWith('@')
                          ? crag.instagram!
                          : '@${crag.instagram}',
                    ),
                  ),
              ],
            ),
          ],

          // Custom Gym Grading Scale (if present)
          if (hasGradingScale) ...[
            const SizedBox(height: 14),
            _buildGymGradingScaleSection(crag.gradingScale),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String content,
    bool isAlert = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAlert
            ? context.palette.hazardContainer.withValues(alpha: 0.3)
            : context.palette.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(
          color: isAlert ? context.palette.hazardText.withValues(alpha: 0.3) : context.palette.border,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isAlert ? context.palette.hazardText : context.palette.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textStyles.caption.copyWith(
                    color: isAlert ? context.palette.hazardText : context.palette.textSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: context.textStyles.bodySmall.copyWith(
                    color: context.palette.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: context.palette.border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: context.palette.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: context.textStyles.caption.copyWith(
                color: context.palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingCard(double lat, double lng) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: context.palette.border, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(Icons.local_parking_rounded, size: 18, color: context.palette.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PARKING COORDINATES',
                  style: context.textStyles.caption.copyWith(
                    color: context.palette.textSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: context.textStyles.bodySmall.copyWith(
                    color: context.palette.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGymGradingScaleSection(List<GymGradeTag> scale) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: context.palette.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GYM GRADING SCALE',
            style: context.textStyles.caption.copyWith(
              color: context.palette.textSecondary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: scale.map((tag) {
              Color tagColor = context.palette.primary;
              if (tag.hex != null && tag.hex!.isNotEmpty) {
                final cleanHex = tag.hex!.replaceAll('#', '');
                final intVal = int.tryParse(cleanHex, radix: 16);
                if (intVal != null) {
                  tagColor = Color(0xFF000000 | intVal);
                }
              }

              final rangeText = (tag.vMin != null && tag.vMax != null)
                  ? ' (V${tag.vMin}–V${tag.vMax})'
                  : '';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.palette.surfaceElevated,
                  borderRadius: AppRadius.borderXs,
                  border: Border.all(color: context.palette.border, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: tagColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${tag.label}$rangeText',
                      style: context.textStyles.caption.copyWith(
                        color: context.palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPlaceholder(bool isIndoor) {
    return Container(
      color: context.palette.surfaceElevated,
      child: Center(
        child: Icon(
          isIndoor ? Icons.fitness_center_rounded : Icons.terrain_rounded,
          size: 56,
          color: context.palette.border,
        ),
      ),
    );
  }

  Widget _buildSectorSelector(
    List<String> sectors,
    int totalRoutes,
    Map<String, int> sectorCounts,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SECTOR SELECT',
                style: context.textStyles.labelSmall.copyWith(
                  color: context.palette.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${sectors.length} zones available',
                style: context.textStyles.caption.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sectors.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = _selectedSector == 'ALL SECTORS';
                return _buildSectorChip(
                  label: 'ALL SECTORS',
                  count: totalRoutes,
                  isSelected: isSelected,
                  onTap: () => setState(() => _selectedSector = 'ALL SECTORS'),
                );
              }
              final sector = sectors[index - 1];
              final count = sectorCounts[sector] ?? 0;
              final isSelected = _selectedSector.toLowerCase() == sector.toLowerCase();
              return _buildSectorChip(
                label: sector.toUpperCase(),
                count: count,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedSector = sector),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectorChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.borderXs,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? context.palette.primary : context.palette.surfaceElevated,
            borderRadius: AppRadius.borderXs,
            border: Border.all(
              color: isSelected ? context.palette.accent : context.palette.border,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.textStyles.labelSmall.copyWith(
                  color: isSelected ? context.palette.onPrimary : context.palette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($count)',
                style: context.textStyles.caption.copyWith(
                  color: isSelected ? context.palette.onPrimary.withValues(alpha: 0.8) : context.palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteDirectoryHeader(int routeCount, Crag crag) {
    final styleSummary = crag.styles.isNotEmpty ? ' • ${crag.styles.join(" / ")}' : '';
    final countLabel = crag.isIndoor ? 'PROBLEMS' : 'PITCHES';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedSector == 'ALL SECTORS'
              ? (crag.isIndoor ? 'All Gym Routes' : 'Routes in All Sectors')
              : 'Routes in $_selectedSector',
          style: context.textStyles.titleLarge.copyWith(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'SHOWING $routeCount $countLabel$styleSummary',
          style: context.textStyles.caption.copyWith(
            color: context.palette.textSecondary,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSortBar() {
    return Row(
      children: [
        Text(
          'SORT:',
          style: context.textStyles.caption.copyWith(
            color: context.palette.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        _buildSortChip('HARD TO EASY', CragRouteSort.gradeHardToEasy),
        const SizedBox(width: 6),
        _buildSortChip('EASY TO HARD', CragRouteSort.gradeEasyToHard),
        const SizedBox(width: 6),
        _buildSortChip('A – Z', CragRouteSort.nameAscending),
      ],
    );
  }

  Widget _buildSortChip(String label, CragRouteSort sort) {
    final isSelected = _sortOption == sort;
    return InkWell(
      onTap: () => setState(() => _sortOption = sort),
      borderRadius: AppRadius.borderXs,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? context.palette.surfaceElevated : Colors.transparent,
          borderRadius: AppRadius.borderXs,
          border: Border.all(
            color: isSelected ? context.palette.accent : context.palette.border,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: context.textStyles.caption.copyWith(
            color: isSelected ? context.palette.accent : context.palette.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteList(List<RouteItem> routes) {
    if (routes.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.terrain_outlined,
              size: 40,
              color: context.palette.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No boulder problems found',
              style: context.textStyles.titleSmall.copyWith(color: context.palette.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: routes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final route = routes[index];
        final subgrade = formatSubgrade(route.grade);

        return InkWell(
          key: Key('crag_route_card_${route.id}'),
          onTap: () {
            context.push(AppRoutes.routeDetailPath(route.id), extra: route);
          },
          borderRadius: AppRadius.borderSm,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: context.palette.border, width: 1.0),
            ),
            child: Row(
              children: [
                GradeChip(grade: route.grade),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        style: context.textStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.palette.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subgrade,
                        style: context.textStyles.caption.copyWith(
                          color: context.palette.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (route.firstAscent != null && route.firstAscent!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'FA: ${route.firstAscent}',
                          style: context.textStyles.caption.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.palette.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
