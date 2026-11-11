import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Visual role of a [SettingsTile].
enum SettingsTileTone {
  /// Standard row: lime-tinted icon, primary text.
  normal,

  /// Irreversible / dangerous action (e.g. Delete Account): hazard-red icon
  /// and title, no chevron.
  destructive,
}

/// What appears on the trailing edge of a [SettingsTile].
enum SettingsTileTrailing {
  /// `>` — navigates to another screen in the app.
  chevron,

  /// External-link arrow — leaves the app (mail, browser, Discord).
  external,

  /// Nothing.
  none,
}

/// One tappable row in a settings list. Reusable for any future setting:
///
/// ```dart
/// SettingsTile(
///   icon: Icons.notifications_outlined,
///   title: 'Notifications',
///   subtitle: 'Hazard alerts near saved crags',
///   onTap: () => context.push(AppRoutes.notifications),
/// )
/// ```
///
/// Place tiles inside a [SettingsGroup], which supplies the card surface,
/// border and dividers — a tile itself is transparent.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.tone = SettingsTileTone.normal,
    this.trailing = SettingsTileTrailing.chevron,
    this.badge,
    this.trailingWidget,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// `null` renders the row disabled (dimmed, not tappable).
  final VoidCallback? onTap;

  final SettingsTileTone tone;
  final SettingsTileTrailing trailing;

  /// Optional short pill next to the title, e.g. `SOON` or `NEW`.
  final String? badge;

  /// Custom trailing content (switch, value label, spinner). Overrides [trailing].
  final Widget? trailingWidget;

  bool get _isDestructive => tone == SettingsTileTone.destructive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.textStyles;
    final enabled = onTap != null;

    final iconColor = _isDestructive ? palette.hazardText : palette.accent;
    final iconBg = _isDestructive ? palette.hazardContainer : palette.surfaceInput;
    final titleColor = _isDestructive ? palette.hazardText : palette.textPrimary;

    final resolvedTrailing = trailingWidget ??
        switch (_isDestructive ? SettingsTileTrailing.none : trailing) {
          SettingsTileTrailing.chevron =>
            Icon(Icons.chevron_right_rounded, size: 20, color: palette.textMuted),
          SettingsTileTrailing.external =>
            Icon(Icons.open_in_new_rounded, size: 18, color: palette.textMuted),
          SettingsTileTrailing.none => null,
        };

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, borderRadius: AppRadius.borderSm),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: text.titleSmall.copyWith(fontSize: 14, color: titleColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          _Badge(label: badge!),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: text.caption.copyWith(color: palette.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (resolvedTrailing != null) ...[
                const SizedBox(width: 8),
                resolvedTrailing,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.palette.primary,
        borderRadius: AppRadius.borderXs,
      ),
      child: Text(
        label,
        style: context.textStyles.micro.copyWith(
          color: context.palette.onPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// A titled card of related [SettingsTile]s, e.g. *LEGAL* → Privacy Policy,
/// Terms & Conditions. Draws one flat surface with a 1px border and hairline
/// dividers between rows.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    super.key,
    this.title,
    required this.children,
  });

  /// Uppercase section label above the card. Omit for an untitled group.
  final String? title;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title!.toUpperCase(),
              style: context.textStyles.labelSmall.copyWith(
                color: palette.textMuted,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: palette.borderSubtle, width: 1.0),
          ),
          // Material gives the tiles' InkWell splashes a surface to paint on;
          // clip keeps them inside the rounded corners.
          child: Material(
            type: MaterialType.transparency,
            borderRadius: AppRadius.borderMd,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 1, color: palette.borderSubtle),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
