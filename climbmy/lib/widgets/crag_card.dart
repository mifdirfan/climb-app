import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/crag.dart';

/// Reusable card representing a climbing crag in the Popular Crags horizontal list,
/// featuring full text-over-image overlay layout with solid flat surfaces (no gradients)
/// and a transparent bottom content container ensuring the full picture is visible.
class CragCard extends StatelessWidget {
  final Crag crag;
  final String? imageUrl;
  final VoidCallback? onTap;

  const CragCard({
    super.key,
    required this.crag,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeImageUrl = imageUrl ?? crag.imageUrl;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderMd,
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? AppColors.surface,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Full Card Image / Texture Placeholder Layer
            Positioned.fill(
              child: activeImageUrl != null && activeImageUrl.isNotEmpty
                  ? Image.network(
                      activeImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(theme),
                    )
                  : _buildPlaceholder(theme),
            ),

            // 2. Solid Tint Scrim for High-Contrast Text Legibility (No Gradient)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.38),
              ),
            ),

            // 3. Text and Information Overlaid On Top of Full Image
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Route count badge & optional Gym label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: AppRadius.borderXs,
                        ),
                        child: Text(
                          crag.routeCount > 0
                              ? '${crag.routeCount}+ Routes'
                              : 'Explore Routes',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (crag.isIndoor)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: AppRadius.borderXs,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.7),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fitness_center_rounded,
                                size: 10,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'GYM',
                                style: AppTextStyles.caption.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Bottom Content: Crag Name, State Location, and Style Tags
                  // Transparent background ensures the full picture is visible across the card height
                  Container(
                    color: Colors.transparent,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Crag Name
                        Text(
                          crag.name,
                          style: AppTextStyles.titleLarge.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),

                        // Location Row
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 14,
                              color: Colors.white70,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                crag.state,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Style Badges (e.g. SPORT, TRAD) with transparent background
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
                                color: Colors.transparent,
                                borderRadius: AppRadius.borderXs,
                                border: Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.7),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                style,
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.landscape_rounded,
          size: 72,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.16),
        ),
      ),
    );
  }
}
