import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/post_form_providers.dart';
import '../core/router/app_router.dart';

class IndoorLogCalendarScreen extends ConsumerWidget {
  const IndoorLogCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentMonth = ref.watch(selectedMonthProvider);
    final sessionsAsync = ref.watch(monthlyIndoorSessionsProvider);

    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    // Weekday is 1 (Mon) to 7 (Sun). Adjust to make Sunday 0 for our grid.
    final firstWeekday = DateTime(currentMonth.year, currentMonth.month, 1).weekday;
    final emptyLeadingDays = firstWeekday == 7 ? 0 : firstWeekday;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: theme.colorScheme.onSurface, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => ref.read(selectedMonthProvider.notifier).update(
                (m) => DateTime(m.year, m.month - 1),
              ),
            ),
            Text(
              '${currentMonth.year}. ${currentMonth.month.toString().padLeft(2, '0')}',
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => ref.read(selectedMonthProvider.notifier).update(
                (m) => DateTime(m.year, m.month + 1),
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Weekday Header (Sun - Sat)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['일', '월', '화', '수', '목', '금', '토'].map((day) {
                return SizedBox(
                  width: 40,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Calendar Grid
          Expanded(
            child: sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (sessions) {
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: emptyLeadingDays + daysInMonth,
                  itemBuilder: (context, index) {
                    if (index < emptyLeadingDays) return const SizedBox.shrink();
                    
                    final day = index - emptyLeadingDays + 1;
                    final date = DateTime(currentMonth.year, currentMonth.month, day);
                    final today = DateTime.now();
                    final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
                    
                    // Find if a session exists on this day
                    final daySessions = sessions.where((s) => s.sessionDate.day == day).toList();
                    final hasSession = daySessions.isNotEmpty;

                    return InkWell(
                      // Make the date clickable regardless of whether there is a session
                      onTap: () {
                        context.push(
                          AppRoutes.indoorLogDaily,
                          extra: {
                            'date': date,
                            'sessions': daySessions,
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        children: [
                          // Day Number or "Today" badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                            decoration: BoxDecoration(
                              color: isToday ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isToday ? 'Today' : day.toString(),
                              style: AppTextStyles.caption.copyWith(
                                color: isToday ? Colors.black : AppColors.textPrimary,
                                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                fontSize: isToday ? 11 : 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Custom Boulder Icon if session exists, otherwise empty spacing
                          if (hasSession) 
                            _buildBoulderIcon()
                          else
                            const SizedBox(height: 28), // Explicit height to maintain grid alignment
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoulderIcon() {
    return Container(
      width: 36,
      height: 28,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 2, backgroundColor: Colors.white24),
          SizedBox(width: 6),
          CircleAvatar(radius: 2, backgroundColor: Colors.white24),
        ],
      ),
    );
  }
}
