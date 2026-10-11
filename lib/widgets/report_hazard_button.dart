import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../util/auth_guard.dart';

/// A floating action button designed for reporting climbing hazards & safety alerts.
///
/// Follows ClimbApp design system tokens with hazard styling, stadium pill radius
/// ([AppRadius.pill]), and responsive theme integration. Tapping navigates to
/// the dedicated 3-step Hazard Reporting flow.
class ReportHazardButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final bool extended;
  final String label;
  final IconData icon;
  final String? heroTag;

  const ReportHazardButton({
    super.key,
    this.onPressed,
    this.extended = true,
    this.label = 'REPORT',
    this.icon = Icons.warning_amber_rounded,
    this.heroTag = 'report_hazard_fab',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = colorScheme.error;
    final foregroundColor = colorScheme.onError;

    void handlePress() {
      if (onPressed != null) {
        onPressed!();
      } else {
        // Automatically guards navigation behind authentication
        requireAuth(
          context,
          ref,
          reason: 'Sign in to report a crag hazard',
          action: () => context.push(AppRoutes.reportHazardSelect),
        );
      }
    }

    if (extended) {
      return FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: handlePress,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 4,
        highlightElevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide(
            color: foregroundColor.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        icon: Icon(
          icon,
          size: 18,
          color: foregroundColor,
        ),
        label: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );
    }

    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: handlePress,
      tooltip: label,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 4,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        side: BorderSide(
          color: foregroundColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Icon(
        icon,
        size: 22,
        color: foregroundColor,
      ),
    );
  }
}

/// Alias for [ReportHazardButton] matching FloatingActionButton naming convention.
typedef ReportHazardFab = ReportHazardButton;
