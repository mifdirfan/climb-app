import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable animated page indicator dots matching the Figma Onboarding design.
class DotsIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final ValueChanged<int>? onDotTapped;

  const DotsIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    this.onDotTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final isActive = index == currentIndex;

        return GestureDetector(
          onTap: onDotTapped != null ? () => onDotTapped!(index) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isActive ? 24.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : AppColors.surfaceElevated,
              borderRadius: AppRadius.borderXs,
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
                width: 0.8,
              ),
            ),
          ),
        );
      }),
    );
  }
}

