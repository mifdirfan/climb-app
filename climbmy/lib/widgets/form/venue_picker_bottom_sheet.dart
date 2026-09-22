import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart';
import '../../models/route_item.dart';
import '../../providers/home_providers.dart';

/// Helper to display the venue picker modal bottom sheet with optional route selection.
void showVenuePickerSheet({
  required BuildContext context,
  required String title,
  required List<Crag> venues,
  required String? selectedVenueId,
  required ValueChanged<Crag> onSelected,
  ValueChanged<RouteItem?>? onRouteSelected,
  bool outdoorOnly = false,
  String? selectedRouteId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return VenuePickerBottomSheet(
        title: title,
        venues: venues,
        selectedVenueId: selectedVenueId,
        onSelected: onSelected,
        onRouteSelected: onRouteSelected,
        outdoorOnly: outdoorOnly,
        selectedRouteId: selectedRouteId,
      );
    },
  );
}

/// Venue selection bottom sheet with search, outdoor-only filtering,
/// and route dropdown selection for outdoor crags.
class VenuePickerBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final List<Crag> venues;
  final String? selectedVenueId;
  final ValueChanged<Crag> onSelected;
  final ValueChanged<RouteItem?>? onRouteSelected;
  final bool outdoorOnly;
  final String? selectedRouteId;

  const VenuePickerBottomSheet({
    super.key,
    required this.title,
    required this.venues,
    required this.selectedVenueId,
    required this.onSelected,
    this.onRouteSelected,
    this.outdoorOnly = false,
    this.selectedRouteId,
  });

  @override
  ConsumerState<VenuePickerBottomSheet> createState() => _VenuePickerBottomSheetState();
}

class _VenuePickerBottomSheetState extends ConsumerState<VenuePickerBottomSheet> {
  late final TextEditingController _filterController;
  String _searchQuery = '';
  Crag? _selectedCrag;
  RouteItem? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
    if (widget.selectedVenueId != null) {
      try {
        _selectedCrag = widget.venues.firstWhere(
          (v) => v.id == widget.selectedVenueId,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (_selectedCrag != null) {
      widget.onSelected(_selectedCrag!);
      widget.onRouteSelected?.call(_selectedRoute);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Filter venues based on outdoorOnly flag and search query
    final availableVenues = widget.outdoorOnly
        ? widget.venues.where((c) => c.isOutdoor).toList()
        : widget.venues;

    final filteredVenues = availableVenues.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.state.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
        border: Border.all(
          color: colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
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
          const SizedBox(height: 16),

          // Title & Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: colorScheme.onSurfaceVariant),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Search Field
          TextField(
            controller: _filterController,
            onChanged: (val) => setState(() => _searchQuery = val),
            style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search by name or state (e.g. Selangor)...',
              prefixIcon: Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _filterController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Selected Crag & Route Dropdown Section (when route selection is active)
          if (_selectedCrag != null && widget.onRouteSelected != null)
            _buildRouteDropdownSection(theme, colorScheme),

          // Venues List
          Expanded(
            child: filteredVenues.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.terrain_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No locations found',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try searching for a different keyword'
                                : 'No locations available in this category.',
                            style: AppTextStyles.caption.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredVenues.length,
                    separatorBuilder: (_, _) => Divider(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final venue = filteredVenues[index];
                      final isSelected = _selectedCrag?.id == venue.id;

                      return Material(
                        color: Colors.transparent,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Icon(
                              venue.isIndoor ? Icons.fitness_center_rounded : Icons.landscape_rounded,
                              size: 20,
                              color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                            ),
                          ),
                          title: Text(
                            venue.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${venue.state} • ${venue.venueType.toUpperCase()}',
                            style: AppTextStyles.caption.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: colorScheme.primary, size: 20)
                              : Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant, size: 20),
                          onTap: () {
                            setState(() {
                              _selectedCrag = venue;
                              _selectedRoute = null; // reset route when crag changes
                            });

                            if (widget.onRouteSelected == null) {
                              widget.onSelected(venue);
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Confirm button when route selection is enabled
          if (_selectedCrag != null && widget.onRouteSelected != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  child: Text(
                    _selectedRoute != null
                        ? 'SELECT CRAG & ROUTE'
                        : 'SELECT CRAG (ALL ROUTES)',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteDropdownSection(ThemeData theme, ColorScheme colorScheme) {
    final routesAsync = ref.watch(cragRoutesProvider(_selectedCrag!.id));
    final routes = routesAsync.value ?? getFallbackRoutesForCrag(_selectedCrag!.id, _selectedCrag!.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.borderSm,
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Route in ${_selectedCrag!.name}:',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Dropdown button for routes in this crag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceInput,
              borderRadius: AppRadius.borderXs,
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1.0,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<RouteItem?>(
                key: const Key('crag_route_dropdown'),
                value: _selectedRoute,
                isExpanded: true,
                dropdownColor: AppColors.surfaceElevated,
                hint: Text(
                  'Entire Crag / General Area (No specific route)',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                items: [
                  DropdownMenuItem<RouteItem?>(
                    value: null,
                    child: Text(
                      'Entire Crag / General Area',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ...routes.map((route) {
                    return DropdownMenuItem<RouteItem?>(
                      value: route,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              route.name,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              borderRadius: AppRadius.borderXs,
                            ),
                            child: Text(
                              route.grade,
                              style: AppTextStyles.caption.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (RouteItem? route) {
                  setState(() {
                    _selectedRoute = route;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
