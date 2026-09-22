import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Filter type for filtering climbing crags by venue category.
enum VenueLegendFilter {
  all,
  boulder,
  gym,
}

/// Floating interactive legend displaying Boulder (red) and Gym (cyan) venues.
/// Adheres to Auto-Layout, theme tokens, and clean callback separation.
class MapLegend extends StatelessWidget {
  final VenueLegendFilter selectedFilter;
  final ValueChanged<VenueLegendFilter>? onFilterChanged;
  final int boulderCount;
  final int gymCount;

  const MapLegend({
    super.key,
    this.selectedFilter = VenueLegendFilter.all,
    this.onFilterChanged,
    this.boulderCount = 0,
    this.gymCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Boulder Legend Item (Red / Outdoor)
          _buildLegendChip(
            context: context,
            label: 'Boulder',
            count: boulderCount,
            dotColor: const Color(0xFFEF4444),
            icon: Icons.terrain_rounded,
            isSelected: selectedFilter == VenueLegendFilter.boulder,
            onTap: () {
              if (onFilterChanged != null) {
                onFilterChanged!(
                  selectedFilter == VenueLegendFilter.boulder
                      ? VenueLegendFilter.all
                      : VenueLegendFilter.boulder,
                );
              }
            },
          ),

          Container(
            height: 16,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: AppColors.borderSubtle,
          ),

          // Gym Legend Item (Cyan / Indoor)
          _buildLegendChip(
            context: context,
            label: 'Gym',
            count: gymCount,
            dotColor: const Color(0xFF06B6D4),
            icon: Icons.fitness_center_rounded,
            isSelected: selectedFilter == VenueLegendFilter.gym,
            onTap: () {
              if (onFilterChanged != null) {
                onFilterChanged!(
                  selectedFilter == VenueLegendFilter.gym
                      ? VenueLegendFilter.all
                      : VenueLegendFilter.gym,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip({
    required BuildContext context,
    required String label,
    required int count,
    required Color dotColor,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? dotColor.withValues(alpha: 0.22) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isSelected
              ? Border.all(color: dotColor, width: 1.2)
              : Border.all(color: Colors.transparent, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color indicator dot
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 13,
              color: isSelected ? dotColor : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '($count)',
                style: AppTextStyles.caption.copyWith(
                  color: isSelected ? dotColor : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

