import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers/home_providers.dart';

/// Horizontal scrollable bar of filter chips for states (Selangor, Perak, Perlis, Johor, etc.).
class FilterChipBar extends ConsumerWidget {
  final List<String> states;

  const FilterChipBar({
    super.key,
    this.states = const ['All', 'Selangor', 'Perak', 'Perlis', 'Johor', 'Pahang'],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedState = ref.watch(selectedStateFilterProvider);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: states.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final state = states[index];
          final isSelected = state == selectedState;

          return InkWell(
            onTap: () {
              ref.read(selectedStateFilterProvider.notifier).setFilter(state);
            },
            borderRadius: AppRadius.borderSm,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceInput,
                borderRadius: AppRadius.borderSm,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  state,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
