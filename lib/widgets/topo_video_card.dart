import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Reusable Topo Video & Beta link hero card for embedding climbing beta links.
/// Matches Figma frame 'Hero Media / Topo Upload Card' (Node 5326:271).
class TopoVideoCard extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const TopoVideoCard({
    super.key,
    this.controller,
    this.onChanged,
  });

  static const List<String> supportedPlatforms = [
    'YouTube',
    'Instagram Reels',
    'TikTok'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadius.borderXl,
        border: Border.all(
          color: context.palette.borderSubtle,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Video Icon Container + Title & Tag
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: context.palette.surfaceInput,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: context.palette.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOPO VIDEO BETA LINK',
                      style: context.textStyles.titleSmall.copyWith(
                        color: context.palette.textPrimary,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'VIDEO EMBED BETA',
                      style: context.textStyles.micro.copyWith(
                        color: context.palette.accent,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Explanatory Subtitle
          Text(
            'Just share the link to the topo video you uploaded on platforms like YouTube, Instagram Reels, TikTok, or Vimeo.',
            style: context.textStyles.bodySmall.copyWith(
              color: context.palette.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // Video URL Text Input
          TextFormField(
            controller: controller,
            onChanged: onChanged,
            style: context.textStyles.bodyMedium.copyWith(
              color: context.palette.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'https://www.youtube.com/watch?v=... or reel URL',
              hintStyle: context.textStyles.bodySmall.copyWith(
                color: context.palette.textMuted,
              ),
              prefixIcon: Icon(
                Icons.link_rounded,
                size: 18,
                color: context.palette.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              filled: true,
              fillColor: context.palette.surfaceInput,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: context.palette.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: context.palette.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Supported Platform Badges
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'SUPPORTED:',
                style: context.textStyles.micro.copyWith(
                  color: context.palette.textMuted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              ...supportedPlatforms.map(
                (platform) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceElevated,
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: context.palette.borderSubtle,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.palette.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        platform,
                        style: context.textStyles.caption.copyWith(
                          color: context.palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

