import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart';

/// Helper to display the venue picker modal bottom sheet.
void showVenuePickerSheet({
  required BuildContext context,
  required String title,
  required List<Crag> venues,
  required String? selectedVenueId,
  required ValueChanged<Crag> onSelected,
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
        onSelected: (venue) {
          onSelected(venue);
          Navigator.of(context).pop();
        },
      );
    },
  );
}

/// Venue selection bottom sheet with full search and empty state handling.
class VenuePickerBottomSheet extends StatefulWidget {
  final String title;
  final List<Crag> venues;
  final String? selectedVenueId;
  final ValueChanged<Crag> onSelected;

  const VenuePickerBottomSheet({
    super.key,
    required this.title,
    required this.venues,
    required this.selectedVenueId,
    required this.onSelected,
  });

  @override
  State<VenuePickerBottomSheet> createState() => _VenuePickerBottomSheetState();
}

class _VenuePickerBottomSheetState extends State<VenuePickerBottomSheet> {
  late final TextEditingController _filterController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final filteredVenues = widget.venues.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.state.toLowerCase().contains(q);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.0),
          left: BorderSide(color: AppColors.borderSubtle, width: 1.0),
          right: BorderSide(color: AppColors.borderSubtle, width: 1.0),
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
                color: AppColors.borderSubtle,
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
                style: AppTextStyles.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _filterController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name or state...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              filled: true,
              fillColor: AppColors.surfaceInput,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          const SizedBox(height: 16),

          // List with Empty State Handling
          Expanded(
            child: filteredVenues.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.terrain_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No locations found',
                            style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try searching for a different keyword'
                                : 'No locations available in this category.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredVenues.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: AppColors.borderSubtle,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final venue = filteredVenues[index];
                      final isSelected = venue.id == widget.selectedVenueId;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceInput,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            venue.isIndoor ? Icons.fitness_center_rounded : Icons.landscape_rounded,
                            size: 20,
                            color: isSelected ? AppColors.onPrimary : AppColors.primaryLight,
                          ),
                        ),
                        title: Text(
                          venue.name,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isSelected ? AppColors.primaryLight : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${venue.state} • ${venue.venueType.toUpperCase()}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                            : const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                        onTap: () => widget.onSelected(venue),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

