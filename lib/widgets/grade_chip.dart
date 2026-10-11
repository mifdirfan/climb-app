import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable grade badge/chip displaying climbing difficulty (e.g., '6b+', '7a', '5c').
class GradeChip extends StatelessWidget {
  final String grade;
  final bool isHighlighted;

  const GradeChip({
    super.key,
    required this.grade,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted ? AppColors.primary : AppColors.surfaceInput,
        borderRadius: AppRadius.borderSm,
        border: Border.all(
          color: isHighlighted ? AppColors.primary : AppColors.border,
          width: 1.0,
        ),
      ),
      child: Text(
        grade,
        style: AppTextStyles.grade.copyWith(
          fontSize: 16,
          color: isHighlighted ? AppColors.onPrimary : AppColors.primary,
        ),
      ),
    );
  }
}

