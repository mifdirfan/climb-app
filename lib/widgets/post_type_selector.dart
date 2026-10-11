import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../providers/post_form_providers.dart';

/// Segmented pill button selector placed at the top of PostScreen
/// allowing climbers to toggle between Outdoor sends and Indoor gym sessions.
class PostTypeSelector extends StatelessWidget {
  final ClimbPostType selectedType;
  final ValueChanged<ClimbPostType> onTypeChanged;

  const PostTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PillOption(
              label: 'Outdoor',
              icon: Icons.landscape_outlined,
              isSelected: selectedType == ClimbPostType.outdoor,
              onTap: () => onTypeChanged(ClimbPostType.outdoor),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _PillOption(
              label: 'Indoor',
              icon: Icons.fitness_center_rounded,
              isSelected: selectedType == ClimbPostType.indoor,
              onTap: () => onTypeChanged(ClimbPostType.indoor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PillOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.onPrimary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? AppColors.onPrimary : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
