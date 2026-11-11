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
          color: context.palette.hazardContainer,
          borderRadius: AppRadius.borderSm,
          border: Border.all(
            color: context.palette.hazardText.withAlpha(80),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: context.palette.hazardText,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: context.textStyles.hazardAlert.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: context.palette.hazardText,
                ),
                onPressed: onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            else
              Icon(
                Icons.chevron_right,
                size: 18,
                color: context.palette.hazardText,
              ),
          ],
        ),
      ),
    );
  }
}

