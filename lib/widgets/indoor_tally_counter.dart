import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart'; 

class IndoorTallyCounter extends StatelessWidget {
  final Map<String, int> tallies;
  final List<GymGradeTag> gradingScale;
  final void Function(String) onIncrement;
  final void Function(String) onDecrement;

  const IndoorTallyCounter({
    super.key,
    required this.tallies,
    this.gradingScale = const [],
    required this.onIncrement,
    required this.onDecrement,
  });

  // Helper to convert hex strings like "#10B981" to Flutter Colors
  Color _parseHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.primary;
    final cleanHex = hexString.replaceAll('#', '');
    final intVal = int.tryParse(cleanHex, radix: 16);
    return intVal != null ? Color(0xFF000000 | intVal) : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (tallies.isEmpty) return const SizedBox.shrink();

    // Prioritize the gym's specific scale. If empty, fallback to the default V-scale map keys.
    final hasCustomScale = gradingScale.isNotEmpty;
    final items = hasCustomScale 
        ? gradingScale.map((t) => t.label).toList() 
        : tallies.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BOULDER SENDS TALLY',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            children: items.map((gradeLabel) {
              final count = tallies[gradeLabel] ?? 0;
              final GymGradeTag? tagInfo = hasCustomScale 
                  ? gradingScale.firstWhere((t) => t.label == gradeLabel) 
                  : null;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Dynamic Label & Color Dot
                    Row(
                      children: [
                        if (tagInfo != null && tagInfo.hex != null) ...[
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _parseHex(tagInfo.hex),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          gradeLabel,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    // Counter Controls
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 22),
                          color: count > 0 ? AppColors.textPrimary : AppColors.textMuted,
                          onPressed: count > 0 ? () => onDecrement(gradeLabel) : null,
                          splashRadius: 20,
                        ),
                        SizedBox(
                          width: 32,
                          child: Text(
                            count.toString(),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: count > 0 ? AppColors.primary : AppColors.textMuted,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 22),
                          color: AppColors.primary,
                          onPressed: () => onIncrement(gradeLabel),
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}