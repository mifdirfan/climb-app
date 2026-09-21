import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// An interactive tally counter for logging indoor boulder sends by grade.
class IndoorTallyCounter extends StatelessWidget {
  final Map<String, int> tallies;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;

  const IndoorTallyCounter({
    super.key,
    required this.tallies,
    required this.onIncrement,
    required this.onDecrement,
  });

  int get totalSends => tallies.values.fold(0, (sum, count) => sum + count);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with total sends badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'BOULDER SENDS TALLY',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                '$totalSends ${totalSends == 1 ? 'send' : 'sends'} total',
                style: AppTextStyles.caption.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid/Wrap of Grade Counters
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tallies.entries.map((entry) {
            final grade = entry.key;
            final count = entry.value;
            final hasSends = count > 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: hasSends ? AppColors.surfaceElevated : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: hasSends
                      ? theme.colorScheme.primary.withValues(alpha: 0.6)
                      : AppColors.borderSubtle,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Grade Label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasSends
                          ? theme.colorScheme.primary.withValues(alpha: 0.2)
                          : AppColors.surfaceInput,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      grade,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: hasSends
                            ? theme.colorScheme.primary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Minus Button
                  InkWell(
                    onTap: count > 0 ? () => onDecrement(grade) : null,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: count > 0
                            ? AppColors.surfaceInput
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.remove_rounded,
                        size: 16,
                        color: count > 0
                            ? AppColors.textPrimary
                            : AppColors.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                  ),

                  // Count Value
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '$count',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: hasSends ? AppColors.textPrimary : AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  // Plus Button
                  InkWell(
                    onTap: () => onIncrement(grade),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
