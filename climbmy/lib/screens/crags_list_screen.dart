import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart';
import '../../providers/home_providers.dart';

/// Alias supporting both CragsListScreen and VenuesListScreen naming.
typedef CragsListScreen = VenuesListScreen;

/// Filter selection for the reusable venues list screen.
enum VenueCategoryFilter { all, crags, gyms }

/// Reusable screen displaying a searchable, filterable list of climbing crags and gyms.
/// Used for "Tick History & Send Log", "Saved Crags & Topos", and other venue collections.
class VenuesListScreen extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final String? emptyMessage;
  final String? emptySubtitle;
  final IconData? emptyIcon;
  final List<Crag>? initialVenues;
  final ValueChanged<Crag>? onVenueTap;

  const VenuesListScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.emptyMessage,
    this.emptySubtitle,
    this.emptyIcon,
    this.initialVenues,
    this.onVenueTap,
  });

  @override
  ConsumerState<VenuesListScreen> createState() => _VenuesListScreenState();
}

class _VenuesListScreenState extends ConsumerState<VenuesListScreen> {
  late final TextEditingController _searchController;
  VenueCategoryFilter _selectedFilter = VenueCategoryFilter.all;
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Use initialVenues if provided (e.g. for testing/mocking), otherwise watch mapVenuesProvider
    final venuesAsync = ref.watch(mapVenuesProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('venues_back_button'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: AppTextStyles.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            )
            ],
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Controls: Search Bar and Category Filter Chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    key: const Key('venues_search_field'),
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search by crag, gym, or state...',
                      hintStyle: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                      prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter Chips Row
                  Row(
                    children: [
                      _buildFilterChip(
                        key: const Key('filter_all'),
                        label: 'All Places',
                        filter: VenueCategoryFilter.all,
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        key: const Key('filter_crags'),
                        label: 'Outdoor Crags',
                        filter: VenueCategoryFilter.crags,
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        key: const Key('filter_gyms'),
                        label: 'Indoor Gyms',
                        filter: VenueCategoryFilter.gyms,
                        colorScheme: colorScheme,
                        theme: theme,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Venues List Content
            Expanded(
              child: widget.initialVenues != null
                  ? _buildVenuesList(theme, colorScheme, widget.initialVenues!)
                  : venuesAsync.when(
                      data: (venues) => _buildVenuesList(theme, colorScheme, venues),
                      loading: () => const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                              const SizedBox(height: 12),
                              Text(
                                'Unable to load places',
                                style: AppTextStyles.titleSmall.copyWith(color: colorScheme.onSurface),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                err.toString(),
                                style: AppTextStyles.caption.copyWith(color: colorScheme.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => ref.refresh(mapVenuesProvider),
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required Key key,
    required String label,
    required VenueCategoryFilter filter,
    required ColorScheme colorScheme,
    required ThemeData theme,
  }) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      key: key,
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildVenuesList(ThemeData theme, ColorScheme colorScheme, List<Crag> venues) {
    // 1. Filter by category
    final categoryFiltered = venues.where((v) {
      if (_selectedFilter == VenueCategoryFilter.crags && !v.isOutdoor) return false;
      if (_selectedFilter == VenueCategoryFilter.gyms && !v.isIndoor) return false;
      return true;
    }).toList();

    // 2. Filter by search query
    final filtered = categoryFiltered.where((v) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final nameMatches = v.name.toLowerCase().contains(q);
      final stateMatches = v.state.toLowerCase().contains(q);
      final addressMatches = (v.address ?? '').toLowerCase().contains(q);
      return nameMatches || stateMatches || addressMatches;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.emptyIcon ?? Icons.landscape_outlined,
                size: 56,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matching locations found'
                    : (widget.emptyMessage ?? 'No locations available'),
                style: AppTextStyles.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try searching for a different crag or city.'
                    : (widget.emptySubtitle ?? 'Locations will appear here as you log sends and save crags.'),
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final venue = filtered[index];
        final isIndoor = venue.isIndoor;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            key: Key('venue_item_${venue.id}'),
            onTap: () {
              if (widget.onVenueTap != null) {
                widget.onVenueTap!(venue);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Text('${venue.name} (${venue.state}) selected'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Venue Type Icon Box
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isIndoor
                          ? colorScheme.secondaryContainer
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      isIndoor ? Icons.fitness_center_rounded : Icons.terrain_rounded,
                      size: 22,
                      color: isIndoor
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name, State & Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venue.name,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                isIndoor && venue.address != null && venue.address!.isNotEmpty
                                    ? '${venue.state} • ${venue.address}'
                                    : '${venue.state} • ${venue.routeCount} routes',
                                style: AppTextStyles.caption.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isIndoor
                          ? colorScheme.secondaryContainer
                          : colorScheme.primaryContainer,
                      borderRadius: AppRadius.borderXs,
                    ),
                    child: Text(
                      isIndoor ? 'GYM' : 'CRAG',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isIndoor
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

