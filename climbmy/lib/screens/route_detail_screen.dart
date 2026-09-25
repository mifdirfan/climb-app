import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../models/crag.dart';
import '../models/hazard_alert.dart';
import '../models/route.dart';
import '../providers/home_providers.dart';
import '../providers/post_form_providers.dart';
import '../util/grade_utils.dart';
import '../providers/hazard_report_providers.dart';

/// Screen displaying climbing Route Details matching Figma frame 5333:9.
/// Implements technical badges with conditional checks, normal Topo image,
/// send ratio bento card, beta & sequence, route hazards, community notes,
/// and single primary action sticky bottom dock ("LOG ASCENT / TICK").
class RouteDetailScreen extends ConsumerStatefulWidget {
  final String routeId;
  final RouteItem? initialRoute;

  const RouteDetailScreen({
    super.key,
    required this.routeId,
    this.initialRoute,
  });

  @override
  ConsumerState<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends ConsumerState<RouteDetailScreen> {
  final List<Map<String, String>> _notes = [
    {
      'user': 'Adam O.',
      'style': 'Redpoint',
      'date': '2 days ago',
      'comment':
          'High feet are crucial on bolt 3. Don\'t skip the subtle knee bar rest before the reachy crux traverse.',
    },
    {
      'user': 'Sarah C.',
      'style': 'Flash',
      'date': '1 week ago',
      'comment':
          'Tufa was slightly damp in the morning. Best climbed around 2 PM once the crag catches warm breeze.',
    },
    {
      'user': 'Hafiz K.',
      'style': 'Onsight',
      'date': '2 weeks ago',
      'comment':
          'Reach past the obvious pocket to find a hidden incut crimp edge above the 5th quickdraw.',
    },
  ];

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.crags);
    }
  }

  void _logAscent(RouteItem route) {
    // 1. Ensure Post mode is Outdoor
    ref.read(postTypeProvider.notifier).setType(ClimbPostType.outdoor);

    // 2. Resolve associated Crag from loaded providers or synthesize from route info
    Crag? resolvedCrag;
    final allCrags = ref.read(outdoorCragsProvider).value ??
        ref.read(cragsProvider).value ??
        ref.read(mapVenuesProvider).value ??
        [];

    if (route.cragId != null && route.cragId!.isNotEmpty) {
      try {
        resolvedCrag = allCrags.firstWhere((c) => c.id == route.cragId);
      } catch (_) {
        resolvedCrag = ref.read(cragDetailProvider(route.cragId!)).value;
      }
    }

    if (resolvedCrag == null && route.cragName != null && route.cragName!.isNotEmpty) {
      try {
        resolvedCrag = allCrags.firstWhere(
          (c) => c.name.toLowerCase() == route.cragName!.toLowerCase(),
        );
      } catch (_) {}
    }

    resolvedCrag ??= Crag(
      id: route.cragId ??
          (route.cragName != null
              ? 'crag-${route.cragName!.toLowerCase().replaceAll(' ', '-')}'
              : 'crag-temp'),
      name: route.cragName ?? 'Batu Caves',
      state: 'Selangor',
    );

    // 3. Pre-fill outdoor form provider:
    // IMPORTANT: setSelectedCrag MUST be called BEFORE setSelectedRouteId & setRouteName
    // because setSelectedCrag resets routeId if the crag changes.
    final notifier = ref.read(outdoorPostFormProvider.notifier);
    notifier.setSelectedCrag(resolvedCrag);
    notifier.setSelectedRouteId(route.id);
    notifier.setRouteName(route.name);
    notifier.setGrade(route.grade);
    notifier.setRouteType(route.routeType);

    // 4. Navigate to Ticks logging screen
    context.push(AppRoutes.ticks);
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          20,
          16,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Climber Note',
                  style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              autofocus: true,
              maxLines: 4,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Share gear requirements, sequence beta, or hold conditions...',
                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final text = noteController.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _notes.insert(0, {
                        'user': 'You (Climber)',
                        'style': 'Beta Note',
                        'date': 'Just now',
                        'comment': text,
                      });
                    });
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Text(
                          'Beta note added to route community log',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    );
                  }
                },
                child: const Text('POST NOTE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(routeDetailProvider(widget.routeId));
    final hazardsAsync = ref.watch(routeHazardsProvider(widget.routeId));

    // Resolve route model
    final route = widget.initialRoute ??
        routeAsync.value ??
        RouteItem(
          id: widget.routeId,
          sectorId: 'sector-damai',
          name: 'Tualang Serenade',
          grade: '7b',
          routeType: 'sport',
          sectorName: 'Damai Central',
          cragName: 'Batu Caves',
          length: '24 Meters',
          boltsCount: 11,
          anchors: '2 Stainless Rings',
          firstAscent: 'A. Honnold (2024)',
          description:
              'Sustained, vertical limestone crimping through the first 4 bolts leading to an explosive crux traverse right on underclings. Keep feet high through the gaston sequence to reach the rest jug before clipping the chain anchor.',
        );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('route_back_button'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: _onBack,
        ),
        title: Text(
          'ROUTE DETAIL',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.primary,
            letterSpacing: 2.0,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surfaceElevated,
                  content: Text(
                    'Link to ${route.name} copied to clipboard',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable route content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Top Context Sub-Nav Banner
                    _buildTopContextBanner(route),

                    const SizedBox(height: 16),

                    // 2. Route Core Specs & Grade Header
                    _buildRouteHeader(route),

                    const SizedBox(height: 14),

                    // 3. Technical Badges Strip (Conditional if/else checks)
                    _buildTechnicalBadgesStrip(route),

                    const SizedBox(height: 18),

                    // 4. Route Topo Visual Frame (Normal Image)
                    _buildRouteTopoFrame(route),

                    const SizedBox(height: 18),

                    // 5. Climber Stats & Send Ratio Bento Card
                    _buildSendRatioCard(route),

                    const SizedBox(height: 18),

                    // 6. Route Beta & Sequence Card
                    _buildBetaCard(route),

                    const SizedBox(height: 18),

                    // 7. Active Route Hazards Card
                    _buildHazardsCard(route, hazardsAsync.value ?? []),

                    const SizedBox(height: 18),

                    // 8. Community Notes & Beta
                    _buildCommunityNotesSection(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 9. Bottom Sticky Action Dock (Single Primary Button per User Instruction)
            _buildBottomStickyDock(route),
          ],
        ),
      ),
    );
  }


// widget 

  Widget _buildTopContextBanner(RouteItem route) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          // Sector Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: AppRadius.borderXs,
            ),
            child: Text(
              route.sectorName?.toUpperCase() ?? 'DAMAI WALL',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Location Subtitle
          Expanded(
            child: Text(
              route.locationSubtitle.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Quick Log Send action
          TextButton(
            key: const Key('quick_log_send_button'),
            onPressed: () => _logAscent(route),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'LOG SEND',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHeader(RouteItem route) {
    final subgrade = formatSubgrade(route.grade);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large Primary Grade Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.borderSm,
          ),
          child: Text(
            route.grade,
            style: AppTextStyles.displayLarge.copyWith(
              fontSize: 26,
              color: AppColors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Route Title and Sub-grade Conversion
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.name.toUpperCase(),
                style: AppTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textLight,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subgrade,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Technical Badges Strip: implements explicit user requirement:
  /// "use if else statement for Technical Badges Strip. if it exist, print it"
  Widget _buildTechnicalBadgesStrip(RouteItem route) {
    final List<Widget> techBadges = [];

    // 1. Route Type badge (if exists)
    if (route.routeType.isNotEmpty) {
      techBadges.add(
        _buildTechBadge(
          icon: Icons.terrain_rounded,
          label: route.routeType.toUpperCase(),
        ),
      );
    }

    // 2. Length badge (if exists)
    if (route.length != null && route.length!.isNotEmpty) {
      techBadges.add(
        _buildTechBadge(
          icon: Icons.straighten_rounded,
          label: route.length!,
        ),
      );
    }

    // 3. Bolts / Quickdraws badge (if exists)
    if (route.boltsCount != null && route.boltsCount! > 0) {
      techBadges.add(
        _buildTechBadge(
          icon: Icons.hardware_rounded,
          label: '${route.boltsCount} Quickdraws',
        ),
      );
    }

    // 4. Anchors badge (if exists)
    if (route.anchors != null && route.anchors!.isNotEmpty) {
      techBadges.add(
        _buildTechBadge(
          icon: Icons.link_rounded,
          label: route.anchors!,
        ),
      );
    }

    // 5. First Ascent badge (if exists)
    if (route.firstAscent != null && route.firstAscent!.isNotEmpty) {
      techBadges.add(
        _buildTechBadge(
          icon: Icons.person_outline_rounded,
          label: 'FA: ${route.firstAscent}',
        ),
      );
    }

    if (techBadges.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: techBadges),
    );
  }

  Widget _buildTechBadge({required IconData icon, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadius.borderSm,
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Route Topo Visual Frame: implements explicit user requirement:
  /// "change Route Topo Visual Frame to normal image"
  Widget _buildRouteTopoFrame(RouteItem route) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Normal Image representation
          route.imageUrl != null && route.imageUrl!.isNotEmpty
              ? Image.network(
                  route.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildTopoPlaceholder(),
                )
              : _buildTopoPlaceholder(),

          // High-contrast scrim for badge overlay visibility
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),

          // Top Info Badges
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.85),
                borderRadius: AppRadius.borderXs,
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Text(
                '${route.boltsCount ?? 11} BOLTS • ${route.length ?? '24M'}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.85),
                borderRadius: AppRadius.borderXs,
                border: Border.all(color: AppColors.border, width: 1.0),
              ),
              child: Text(
                'PITCH 1 OF 1',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Bottom Label
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.85),
                borderRadius: AppRadius.borderXs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'DAMAI KARST TOPO',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopoPlaceholder() {
    return Container(
      color: AppColors.surfaceElevated,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terrain_rounded, size: 54, color: AppColors.border),
            SizedBox(height: 8),
            Text(
              'Limestone Pillar Topo',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendRatioCard(RouteItem route) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '4.9 (68 reviews)',
                    style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              Text(
                '148 Logged Sends',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Community Consensus
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '88% Consensus: ${route.grade}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Solid ${route.grade} • Crux at B4',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Segmented Send Ratio Bar
          ClipRRect(
            borderRadius: AppRadius.borderXs,
            child: Row(
              children: [
                Expanded(
                  flex: 56, // Redpoint (84 / 148)
                  child: Container(height: 8, color: AppColors.primary),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 22, // Flash (32 / 148)
                  child: Container(height: 8, color: AppColors.primaryVariant),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: 22, // Onsight (32 / 148)
                  child: Container(height: 8, color: AppColors.primaryLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Ratio breakdown legend
          Row(
            children: [
              _buildLegendDot(AppColors.primary, 'Redpoint 56% (84)'),
              const Spacer(),
              _buildLegendDot(AppColors.primaryVariant, 'Flash 22% (32)'),
              const Spacer(),
              _buildLegendDot(AppColors.primaryLight, 'Onsight 22% (32)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBetaCard(RouteItem route) {
    final betaText = route.description != null && route.description!.isNotEmpty
        ? route.description!
        : 'Sustained, vertical limestone crimping through the first 4 bolts leading to an explosive crux traverse right on underclings. Keep feet high through the gaston sequence to reach the rest jug before clipping the chain anchor.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROUTE BETA & SEQUENCE',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            betaText,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),

          // Required Gear Pill
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.fitness_center_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'GEAR: ${route.length ?? '60m / 70m rope'}, ${route.boltsCount ?? 12} quickdraws, long runners for bolt 4.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Video Beta button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Text(
                      'Opening community video beta clip...',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_fill_rounded, size: 18, color: AppColors.primary),
              label: const Text('WATCH VIDEO BETA (YOUTUBE / REEL)'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardsCard(RouteItem route, List<HazardAlert> hazards) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVE ROUTE HAZARDS (${hazards.length})',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.hazardText,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (hazards.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.hazardContainer,
                    borderRadius: AppRadius.borderXs,
                  ),
                  child: Text(
                    'CAUTION',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.hazardText,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (hazards.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No active safety hazards reported for this pitch.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            )
          else
            ...hazards.map(
              (hazard) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.hazardContainer.withValues(alpha: 0.5),
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: AppColors.hazardText.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.hazardText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hazard.hazardType.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.hazardText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hazard.description,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Report New Hazard Button
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              key: const Key('report_hazard_on_route_button'),
              onPressed: () {
                context.push(AppRoutes.reportHazardForm);
              },
              icon: const Icon(Icons.add_alert_rounded, size: 16, color: AppColors.warning),
              label: Text(
                '+ REPORT NEW HAZARD',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CLIMBER NOTES & BETA (${_notes.length})',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              key: const Key('add_beta_note_button'),
              onPressed: _showAddNoteDialog,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '+ ADD NOTE',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ..._notes.map(
          (note) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.surfaceElevated,
                      child: Text(
                        note['user']!.substring(0, 1),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      note['user']!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: AppRadius.borderXs,
                      ),
                      child: Text(
                        note['style']!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryLight,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      note['date']!,
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  note['comment']!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bottom Sticky Action Dock: implements explicit user requirement:
  /// "for Bottom Sticky Action Dock remove secondary button"
  Widget _buildBottomStickyDock(RouteItem route) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      child: ElevatedButton.icon(
        key: const Key('route_log_ascent_button'),
        onPressed: () => _logAscent(route),
        icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: const Text('LOG ASCENT / TICK'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.borderSm),
        ),
      ),
    );
  }
}
