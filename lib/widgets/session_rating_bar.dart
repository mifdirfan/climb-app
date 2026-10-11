import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Interactive 1-to-5 star rating bar for logging session satisfaction.
class SessionRatingBar extends StatelessWidget {
  final int? rating;
  final ValueChanged<int> onRatingChanged;

  const SessionRatingBar({
    super.key,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SESSION RATING',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFilled = rating != null && starIndex <= rating!;

                  return InkWell(
                    onTap: () => onRatingChanged(starIndex),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Icon(
                        isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 28,
                        color: isFilled ? AppColors.warning : AppColors.textMuted,
                      ),
                    ),
                  );
                }),
              ),
              Text(
                rating != null ? '$rating / 5' : 'Unrated',
                style: AppTextStyles.titleSmall.copyWith(
                  color: rating != null ? AppColors.textPrimary : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
