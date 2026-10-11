import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/crag.dart';

/// Draggable scrollable bottom sheet displaying climbing venues (crags & gyms)
/// currently visible in the map's viewport.
class VisiblePlacesSheet extends StatelessWidget {
  final List<Crag> venues;
  final Crag? selectedVenue;
  final ValueChanged<Crag>? onVenueTap;

  const VisiblePlacesSheet({
    super.key,
    required this.venues,
    this.selectedVenue,
    this.onVenueTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      key: const Key('boulder_list_sheet'),
      initialChildSize: 0.14,
      minChildSize: 0.07,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.07, 0.14, 0.5, 0.85],
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
                color: Colors.black.withValues(alpha: 0.25),
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
              // Top drag handle & header bar
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 8),

                    // Header row: "Places in view" + badge count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'PLACES IN VIEW',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.1,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: AppRadius.borderPill,
                                ),
                                child: Text(
                                  '${venues.length}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),

              // Empty state when no venues are in view
              if (venues.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.explore_off_outlined,
                            size: 32,
                            color: colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No climbing places in this view',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pan or zoom out the map to discover venues nearby',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // List of places currently visible in the map
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final venue = venues[index];
                        final isSelected = selectedVenue?.id == venue.id;

                        return _VenuePlaceItem(
                          key: Key('visible_venue_${venue.id}'),
                          venue: venue,
                          isSelected: isSelected,
                          onTap: () => onVenueTap?.call(venue),
                        );
                      },
                      childCount: venues.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Clickable venue card element within the visible places bottom sheet
class _VenuePlaceItem extends StatelessWidget {
  final Crag venue;
  final bool isSelected;
  final VoidCallback onTap;

  const _VenuePlaceItem({
    super.key,
    required this.venue,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isIndoor = venue.isIndoor;
    final accentColor = isIndoor ? colorScheme.secondary : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: isSelected
            ? accentColor.withValues(alpha: 0.12)
            : (theme.cardTheme.color ?? colorScheme.surface),
        borderRadius: AppRadius.borderSm,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderSm,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              borderRadius: AppRadius.borderSm,
              border: Border.all(
                color: isSelected ? accentColor : colorScheme.outlineVariant,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Icon indicator
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Icon(
                    isIndoor ? Icons.fitness_center_rounded : Icons.terrain_rounded,
                    size: 18,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 12),

                // Name & Location
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        venue.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isIndoor ? "Indoor Gym" : "Outdoor Crag"} • ${venue.state}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                const SizedBox(width: 4),

                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
