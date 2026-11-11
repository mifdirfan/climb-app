import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../models/tick.dart';
import '../providers/auth_providers.dart';
import '../providers/logbook_providers.dart';
import '../widgets/auth_required_view.dart';
import '../widgets/grade_chip.dart';

/// Profile > "Tick History & Send Log": the signed-in user's own ticks.
///
/// Reads [myTicksProvider] (scoped to the auth user). Guests see
/// [AuthRequiredView]; tapping a tick opens its route detail.
class TickHistoryScreen extends ConsumerWidget {
  const TickHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    if (!isAuthenticated) {
      return const AuthRequiredView(
        title: 'Your Send Log',
        subtitle: 'Sign in to see your redpoints, flashes, and onsights.',
        redirectPath: AppRoutes.tickHistory,
        icon: Icons.history_rounded,
        showAppBar: true,
      );
    }

    final theme = Theme.of(context);
    final ticksAsync = ref.watch(myTicksProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('tick_history_back_button'),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
        title: Text(
          'Tick History & Send Log',
          style: context.textStyles.titleLarge.copyWith(
            color: context.palette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ticksAsync.when(
          data: (ticks) => ticks.isEmpty
              ? const _EmptyLog()
              : RefreshIndicator(
                  color: context.palette.accent,
                  onRefresh: () {
                    debugPrint('--> [LOGBOOK:UI] Pull-to-refresh tick log');
                    return ref.refresh(myTicksProvider.future);
                  },
                  child: _TickList(ticks: ticks),
                ),
          loading: () => Center(
            child: CircularProgressIndicator(color: context.palette.accent),
          ),
          error: (err, _) => _ErrorState(
            message: err.toString(),
            onRetry: () {
              debugPrint('--> [LOGBOOK:UI] Retry tick log');
              ref.invalidate(myTicksProvider);
            },
          ),
        ),
      ),
    );
  }
}

class _TickList extends StatelessWidget {
  const _TickList({required this.ticks});
  final List<Tick> ticks;

  @override
  Widget build(BuildContext context) {
    final sends = ticks.where((t) => t.isCleanSend).length;
    final projects = ticks.where((t) => t.tickType.toLowerCase() == 'project').length;
    final crags = ticks.map((t) => t.cragName).whereType<String>().toSet().length;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: ticks.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 16 : 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Row(
            children: [
              Expanded(child: _SummaryStat(label: 'SENDS', value: sends)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryStat(label: 'PROJECTS', value: projects)),
              const SizedBox(width: 8),
              Expanded(child: _SummaryStat(label: 'CRAGS', value: crags)),
            ],
          );
        }
        return _TickCard(tick: ticks[index - 1]);
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.palette.borderSubtle, width: 1.0),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: context.textStyles.headlineSmall.copyWith(
              color: context.palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textStyles.caption.copyWith(
              color: context.palette.textMuted,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _TickCard extends StatelessWidget {
  const _TickCard({required this.tick});
  final Tick tick;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _formattedDate {
    final d = tick.climbedAt;
    return '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
  }

  String get _location {
    final parts = [tick.cragName, tick.sectorName]
        .whereType<String>()
        .where((s) => s.isNotEmpty);
    return parts.isEmpty ? 'Unknown crag' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final isProject = tick.tickType.toLowerCase() == 'project';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('tick_item_${tick.id}'),
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () {
          debugPrint('--> [LOGBOOK:UI] Open route ${tick.routeId} from tick ${tick.id}');
          context.push(AppRoutes.routeDetailPath(tick.routeId));
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.palette.borderSubtle, width: 1.0),
          ),
          child: Row(
            children: [
              if (tick.routeGrade != null && tick.routeGrade!.isNotEmpty) ...[
                GradeChip(grade: tick.routeGrade!, isHighlighted: tick.isCleanSend),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tick.routeName ?? 'Unnamed route',
                      style: context.textStyles.titleSmall.copyWith(
                        color: context.palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _location,
                      style: context.textStyles.caption.copyWith(color: context.palette.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isProject ? context.palette.surfaceElevated : context.palette.primary,
                      borderRadius: AppRadius.borderXs,
                    ),
                    child: Text(
                      tick.styleDisplayName.toUpperCase(),
                      style: context.textStyles.labelSmall.copyWith(
                        color: isProject ? context.palette.textSecondary : context.palette.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formattedDate,
                    style: context.textStyles.caption.copyWith(color: context.palette.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLog extends StatelessWidget {
  const _EmptyLog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 56,
              color: context.palette.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No ticks or sends logged yet',
              style: context.textStyles.titleMedium.copyWith(
                color: context.palette.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Log your sends in the Ticks tab to build your climbing logbook!',
              style: context.textStyles.caption.copyWith(color: context.palette.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(
              'Unable to load your send log',
              style: context.textStyles.titleSmall.copyWith(color: context.palette.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: context.textStyles.caption.copyWith(color: context.palette.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
