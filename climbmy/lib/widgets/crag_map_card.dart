import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_theme.dart';
import '../models/crag.dart';

/// Reusable floating preview card displayed when a crag marker is selected on the map.
class CragMapCard extends StatelessWidget {
  final Crag crag;
  final VoidCallback? onClose;
  final VoidCallback? onTapDetails;

  const CragMapCard({
    super.key,
    required this.crag,
    this.onClose,
    this.onTapDetails,
  });

  Future<void> _openDirections() async {
    if (crag.parkingLat == null || crag.parkingLong == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${crag.parkingLat},${crag.parkingLong}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCoordinates = crag.parkingLat != null && crag.parkingLong != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name & Close button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crag.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
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
                            crag.venueType.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          crag.state,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onClose != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  onPressed: onClose,
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Metadata row: Route count & styles
          Row(
            children: [
              const Icon(
                Icons.terrain_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                '${crag.routeCount} routes',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 14),
              if (crag.styles.isNotEmpty) ...[
                const Icon(
                  Icons.straighten_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    crag.styles.join(' • '),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),

          if (crag.approachNotes != null && crag.approachNotes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              crag.approachNotes!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: 14),

          // Action Buttons: Directions and Details
          Row(
            children: [
              if (hasCoordinates)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openDirections,
                    icon: const Icon(Icons.directions_rounded, size: 16),
                    label: const Text('DIRECTIONS'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: AppTextStyles.labelMedium,
                    ),
                  ),
                ),
              if (hasCoordinates) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onTapDetails,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('VIEW CRAG'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    textStyle: AppTextStyles.labelMedium,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

