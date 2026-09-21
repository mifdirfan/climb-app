import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// A floating action button designed for reporting climbing hazards & safety alerts.
///
/// Follows ClimbApp design system tokens with hazard styling, stadium pill radius
/// ([AppRadius.pill]), and responsive theme integration.
class ReportHazardButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool extended;
  final String label;
  final IconData icon;
  final String? heroTag;

  const ReportHazardButton({
    super.key,
    this.onPressed,
    this.extended = true,
    this.label = 'REPORT HAZARD',
    this.icon = Icons.warning_amber_rounded,
    this.heroTag = 'report_hazard_fab',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor = colorScheme.error;
    final foregroundColor = colorScheme.onError;

    if (extended) {
      return FloatingActionButton.extended(
        heroTag: heroTag,
        onPressed: onPressed ?? () => showReportModal(context),
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
      onPressed: onPressed ?? () => showReportModal(context),
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

  /// Displays the interactive hazard report modal bottom sheet.
  static Future<void> showReportModal(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ReportHazardBottomSheet(),
    );
  }
}

/// Alias for [ReportHazardButton] matching FloatingActionButton naming convention.
typedef ReportHazardFab = ReportHazardButton;

/// Bottom sheet modal for filing climbing hazard alerts.
class ReportHazardBottomSheet extends StatefulWidget {
  const ReportHazardBottomSheet({super.key});

  @override
  State<ReportHazardBottomSheet> createState() => _ReportHazardBottomSheetState();
}

class _ReportHazardBottomSheetState extends State<ReportHazardBottomSheet> {
  String _selectedHazardType = 'wasps';
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  final List<Map<String, String>> _hazardTypes = const [
    {'key': 'wasps', 'label': 'Wasps / Bees', 'icon': '🐝'},
    {'key': 'loose_rock', 'label': 'Loose Rock', 'icon': '🪨'},
    {'key': 'bad_bolt', 'label': 'Bad Bolt', 'icon': '🔩'},
    {'key': 'other', 'label': 'Other Danger', 'icon': '⚠️'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle, width: 1.0),
          left: BorderSide(color: AppColors.borderSubtle, width: 1.0),
          right: BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: theme.colorScheme.onError,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Report Hazard',
                        style: AppTextStyles.titleLarge,
                      ),
                      Text(
                        'Alert fellow climbers about safety concerns',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Hazard Type Section
            Text(
              'HAZARD TYPE',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),

            // Hazard Type Selection Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _hazardTypes.map((type) {
                final isSelected = type['key'] == _selectedHazardType;
                return ChoiceChip(
                  label: Text('${type['icon']} ${type['label']}'),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.error,
                  backgroundColor: AppColors.surfaceInput,
                  labelStyle: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? theme.colorScheme.onError : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.onError.withValues(alpha: 0.5)
                        : AppColors.border,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedHazardType = type['key']!;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Location
            Text(
              'LOCATION / WALL (OPTIONAL)',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g., Damai Wall, Route: Banana Jam',
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'DESCRIPTION',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Describe the hazard, loose rocks, wasp nest, or spun bolt...',
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Hazard report submitted. Thank you for keeping the crag safe!',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('SUBMIT HAZARD REPORT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

