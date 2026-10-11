import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../models/crag.dart';
import '../models/hazard_alert.dart';
import '../models/route.dart';
import '../providers/home_providers.dart';
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
  bool _isOfflineSaved = false;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cragAsync = ref.watch(cragDetailProvider(widget.cragId));
    final routesAsync = ref.watch(cragRoutesProvider(widget.cragId));
    final hazardsAsync = ref.watch(cragHazardsProvider(widget.cragId));

    // Resolve crag entity without mock data
    final crag = widget.initialCrag ?? cragAsync.value;

    if (crag == null) {
      if (cragAsync.isLoading) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            leading: IconButton(
              key: const Key('crag_back_button'),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              onPressed: _onBack,
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            key: const Key('crag_back_button'),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            onPressed: _onBack,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.hazardText),
                const SizedBox(height: 12),
                Text(
                  'Venue Not Found',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Could not locate venue records in Supabase.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('crag_back_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: _onBack,
        ),
        title: Text(
          isIndoor ? 'GYM' : 'CRAG',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        actions: [
          if (!isIndoor)
            IconButton(
              icon: Icon(
                _isOfflineSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                color: _isOfflineSaved ? AppColors.primary : AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() => _isOfflineSaved = !_isOfflineSaved);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Text(
                      _isOfflineSaved
                          ? '${crag.name} saved for offline topo guide'
                          : '${crag.name} removed from offline storage',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
        ],
      ),
      body: routesAsync.when(
        data: (routes) => _buildContent(theme, crag, routes, hazardsAsync.value ?? []),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.hazardText),
                const SizedBox(height: 12),
                Text('Error loading routes', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Text('$err', style: AppTextStyles.caption, textAlign: TextAlign.center),
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
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Filter by name, grade, or style...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
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
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1.0),
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
                color: AppColors.surfaceElevated,
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
                color: Colors.black.withValues(alpha: 0.45),
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
                        color: AppColors.background.withValues(alpha: 0.85),
                        borderRadius: AppRadius.borderXs,
                      ),
                      child: Text(
                        '${crag.state.toUpperCase()}, MALAYSIA • $typeLabel$countSuffix',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      crag.name,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textLight,
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
                              color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                              borderRadius: AppRadius.borderXs,
                              border: Border.all(color: AppColors.border, width: 0.8),
                            ),
                            child: Text(
                              style.toUpperCase(),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 10,
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
                setState(() => _isOfflineSaved = !_isOfflineSaved);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Text(
                      _isOfflineSaved
                          ? '${crag.name} offline topo guide cached'
                          : '${crag.name} offline topo guide removed',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                _isOfflineSaved ? Icons.check_circle_rounded : Icons.file_download_outlined,
                size: 18,
                color: _isOfflineSaved ? AppColors.primary : AppColors.textPrimary,
              ),
              label: Text(
                _isOfflineSaved ? 'OFFLINE TOPO DOWNLOADED' : 'DOWNLOAD OFFLINE TOPO',
                style: AppTextStyles.labelMedium.copyWith(
                  color: _isOfflineSaved ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: _isOfflineSaved ? AppColors.primary : AppColors.border,
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
            ? AppColors.hazardContainer.withValues(alpha: 0.3)
            : AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(
          color: isAlert ? AppColors.hazardText.withValues(alpha: 0.3) : AppColors.border,
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isAlert ? AppColors.hazardText : AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: isAlert ? AppColors.hazardText : AppColors.textSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
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
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
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
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_parking_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PARKING COORDINATES',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
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
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GYM GRADING SCALE',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: scale.map((tag) {
              Color tagColor = AppColors.primary;
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
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadius.borderXs,
                  border: Border.all(color: AppColors.border, width: 1.0),
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
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
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
      color: AppColors.surfaceElevated,
      child: Center(
        child: Icon(
          isIndoor ? Icons.fitness_center_rounded : Icons.terrain_rounded,
          size: 56,
          color: AppColors.border,
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
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${sectors.length} zones available',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
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
            color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
            borderRadius: AppRadius.borderXs,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($count)',
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? AppColors.onPrimary.withValues(alpha: 0.8) : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
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
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'SHOWING $routeCount $countLabel$styleSummary',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
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
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
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
          color: isSelected ? AppColors.surfaceElevated : Colors.transparent,
          borderRadius: AppRadius.borderXs,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 10,
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
            const Icon(
              Icons.terrain_outlined,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No boulder problems found',
              style: AppTextStyles.titleSmall.copyWith(color: AppColors.textSecondary),
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
              color: AppColors.surface,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: AppColors.border, width: 1.0),
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
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subgrade,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (route.firstAscent != null && route.firstAscent!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'FA: ${route.firstAscent}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
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
