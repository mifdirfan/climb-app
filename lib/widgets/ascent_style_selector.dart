import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Ascent style selection row (Flash, Redpoint, Onsight, Project).
/// Matches Figma frame 'Ascent Style / Status Pills' (Node 5326:314).
class AscentStyleSelector extends StatelessWidget {
  final String selectedStyle;
  final ValueChanged<String> onSelected;

  const AscentStyleSelector({
    super.key,
    required this.selectedStyle,
    required this.onSelected,
  });

  static const List<String> styles = [
    'Flash',
    'Redpoint',
    'Onsight',
    'Project',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ASCENT STYLE',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: styles.map((style) {
            final isSelected = style.toLowerCase() == selectedStyle.toLowerCase();
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => onSelected(style.toLowerCase()),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceInput,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      style,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isSelected ? AppColors.onPrimary : AppColors.textMuted,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

