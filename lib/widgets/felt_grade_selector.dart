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

  /// 'color' resolves against the active [AppPalette] so tones adapt to light/dark.
  static final List<Map<String, dynamic>> _options = [
    {'value': 'easy', 'label': 'Easy', 'icon': Icons.sentiment_satisfied_rounded, 'color': (AppPalette p) => p.accent},
    {'value': 'average', 'label': 'Average', 'icon': Icons.sentiment_neutral_rounded, 'color': (AppPalette p) => p.primaryLight},
    {'value': 'hard', 'label': 'Hard', 'icon': Icons.whatshot_rounded, 'color': (AppPalette p) => p.warning},
    {'value': 'limit', 'label': 'Limit', 'icon': Icons.local_fire_department_rounded, 'color': (AppPalette p) => p.hazardText},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'INTENSITY',
          style: context.textStyles.labelSmall.copyWith(
            color: context.palette.textMuted,
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
            final color = (opt['color'] as Color Function(AppPalette))(context.palette);
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
                      color: isSelected ? color.withValues(alpha: 0.15) : context.palette.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected ? color : context.palette.borderSubtle,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 20,
                          color: isSelected ? color : context.palette.textMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: context.textStyles.caption.copyWith(
                            color: isSelected ? color : context.palette.textMuted,
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
