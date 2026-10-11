import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/hazard_alert.dart';

/// Reusable banner displaying active climbing safety alerts & hazard warnings.
class HazardAlertBanner extends StatelessWidget {
  final HazardAlert? alert;
  final String? customMessage;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const HazardAlertBanner({
    super.key,
    this.alert,
    this.customMessage,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final message = customMessage ??
        (alert != null
            ? '${alert!.hazardType.toUpperCase()}: ${alert!.description}'
            : '⚠️ Wasps reported at Damai Wall');

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.borderSm,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.hazardContainer,
          borderRadius: AppRadius.borderSm,
          border: Border.all(
            color: AppColors.hazardText.withAlpha(80),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.hazardText,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.hazardAlert.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.hazardText,
                ),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.hazardText,
              ),
          ],
        ),
      ),
    );
  }
}

