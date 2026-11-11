import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/indoor_session.dart';

class DailyIndoorLogScreen extends StatelessWidget {
  final DateTime date;
  final List<IndoorSession> sessions;

  const DailyIndoorLogScreen({
    super.key,
    required this.date,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          dateStr,
          style: context.textStyles.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: sessions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center_rounded, size: 56, color: context.palette.borderSubtle),
                  const SizedBox(height: 16),
                  Text(
                    'No sessions logged on this day.',
                    style: context.textStyles.bodyMedium.copyWith(color: context.palette.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.palette.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Gym Name and Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            session.gymName ?? 'Unknown Gym',
                            style: context.textStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (session.rating != null)
                            Row(
                              children: [
                                Icon(Icons.star_rounded, color: context.palette.warning, size: 16),
                                const SizedBox(width: 4),
                                Text('${session.rating}/5', style: context.textStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Meta details: Duration & Intensity
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: context.palette.textMuted),
                          const SizedBox(width: 6),
                          Text('${session.durationMinutes ?? 0} mins', style: context.textStyles.bodySmall),
                          const SizedBox(width: 16),
                          Icon(Icons.local_fire_department_outlined, size: 14, color: context.palette.textMuted),
                          const SizedBox(width: 6),
                          Text('Intensity: ${session.feltGrade?.toUpperCase() ?? "N/A"}', style: context.textStyles.bodySmall),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1),
                      ),
                      // Sends Tally Breakdown
                      Text(
                        'BOULDER SENDS',
                        style: context.textStyles.caption.copyWith(color: context.palette.textMuted, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: session.gradeTallies.entries
                            .where((e) => e.value > 0)
                            .map((e) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: context.palette.surfaceElevated,
                                    borderRadius: BorderRadius.circular(AppRadius.sm),
                                    border: Border.all(color: context.palette.borderSubtle),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(e.key, style: context.textStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(width: 6),
                                      Text('x${e.value}', style: context.textStyles.bodySmall.copyWith(color: context.palette.accent, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                      // Optional Notes
                      if (session.notes != null && session.notes!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.palette.surfaceInput,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            session.notes!,
                            style: context.textStyles.bodySmall.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}