import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/crag.dart';

/// Reusable card representing a climbing crag in the Popular Crags horizontal list.
class CragCard extends StatelessWidget {
  final Crag crag;
  final VoidCallback? onTap;

  const CragCard({
    super.key,
    required this.crag,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? AppColors.surfaceElevated,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: AppColors.borderSubtle,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image / Visual banner with gradient & route badge
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF474746),
                      Color(0xFF2A2A2A),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Texture/Climbing Icon placeholder
                    Center(
                      child: Icon(
                        Icons.landscape_rounded,
                        size: 48,
                        color: AppColors.textSecondary.withAlpha(50),
                      ),
                    ),
                    // Route Count Badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: AppRadius.borderXs,
                        ),
                        child: Text(
                          crag.routeCount > 0
                              ? '${crag.routeCount}+ Routes'
                              : 'Explore Routes',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card Bottom Details
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Crag Name
                    Text(
                      crag.name,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Location Row
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            crag.state,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Style Badges (e.g. SPORT, TRAD)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: crag.styles.map((style) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceInput,
                            borderRadius: AppRadius.borderXs,
                            border: Border.all(
                              color: AppColors.border,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            style,
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

