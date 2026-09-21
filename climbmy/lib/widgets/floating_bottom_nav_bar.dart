import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Navigation item model for [FloatingBottomNavBar].
class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// A compact, floating bottom navigation bar inspired by Instagram's
/// minimalist aesthetic.
///
/// Features:
/// - Floating pill container with rounded borders and elevation.
/// - Spacing from screen edges and bottom safe area.
/// - Instagram-style monochrome icons: active item is bold/filled in white without
///   accent colors, and inactive item is outlined and muted.
/// - Compact height and icon sizing for a clean, non-intrusive look.
class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;
  final Color backgroundColor;
  final double elevation;

  /// Default items matching ClimbApp's main navigation destinations.
  static const List<FloatingNavItem> defaultItems = [
    FloatingNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Crags',
    ),
    FloatingNavItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
      label: 'Map',
    ),
    FloatingNavItem(
      icon: Icons.check_circle_outline_rounded,
      activeIcon: Icons.check_circle_rounded,
      label: 'Ticks',
    ),
    FloatingNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultItems,
    this.backgroundColor = Colors.transparent,
    this.elevation = 0
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.borderSubtle.withValues(alpha: 0.7),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: Tooltip(
                      message: item.label,
                      child: InkWell(
                        onTap: () => onTap(index),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        child: Center(
                          child: AnimatedScale(
                            scale: isSelected ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: isSelected ? 24 : 22,
                              color: isSelected
                                  ? AppColors.textLight
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

