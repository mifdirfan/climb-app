import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Effort level selector for indoor sessions ('easy', 'average', 'hard', 'limit').
class FeltGradeSelector extends StatelessWidget {
  final String? selectedFeltGrade;
  final ValueChanged<String?> onSelected;

  const FeltGradeSelector({
    super.key,
    required this.selectedFeltGrade,
    required this.onSelected,
  });

  static const List<Map<String, dynamic>> _options = [
    {'value': 'easy', 'label': 'Easy', 'icon': Icons.sentiment_satisfied_rounded, 'color': AppColors.primary},
    {'value': 'average', 'label': 'Average', 'icon': Icons.sentiment_neutral_rounded, 'color': AppColors.primaryLight},
    {'value': 'hard', 'label': 'Hard', 'icon': Icons.whatshot_rounded, 'color': AppColors.warning},
    {'value': 'limit', 'label': 'Limit', 'icon': Icons.local_fire_department_rounded, 'color': AppColors.hazardText},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERCEIVED EFFORT / INTENSITY',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _options.map((opt) {
            final value = opt['value'] as String;
            final label = opt['label'] as String;
            final icon = opt['icon'] as IconData;
            final color = opt['color'] as Color;
            final isSelected = selectedFeltGrade == value;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () {
                    if (isSelected) {
                      onSelected(null);
                    } else {
                      onSelected(value);
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withValues(alpha: 0.15) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected ? color : AppColors.borderSubtle,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isSelected ? color : AppColors.textMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: AppTextStyles.caption.copyWith(
                            color: isSelected ? color : AppColors.textMuted,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
