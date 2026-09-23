// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart';
import '../../models/route_item.dart';
import '../../models/hazard_alert.dart';
import '../../providers/home_providers.dart';
import '../../widgets/crag_card.dart';
import '../../widgets/route_item_card.dart';
import '../../widgets/hazard_alert_banner.dart';
import '../../widgets/filter_chip_bar.dart';

/// Main Home screen of ClimbApp matching the Figma 'Home' frame (Node 5315:2).
class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cragsAsync = ref.watch(cragsProvider);
    final routesAsync = ref.watch(recentRoutesProvider);
    final alertsAsync = ref.watch(hazardAlertsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildCragsAppBar(),
      body: _buildCragsHomeContent(theme, cragsAsync, routesAsync, alertsAsync),
    );
  }

  AppBar _buildCragsAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.terrain_rounded),
        onPressed: () {
          // Placeholder for navigation drawer or menu
        },
      ),
      title: Text(
        'Crag',
        style: AppTextStyles.displayLarge.copyWith(
          fontSize: 28, 
          color: AppColors.textPrimary
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () {
            // Placeholder for notifications
          },
        ),
      ],
    );
  }

  Widget _buildCragsHomeContent(
    ThemeData theme,
    AsyncValue<List<Crag>> cragsAsync,
    AsyncValue<List<RouteItem>> routesAsync,
    AsyncValue<List<HazardAlert>> alertsAsync,
  ) {
    return SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(cragsProvider);
            ref.invalidate(recentRoutesProvider);
            ref.invalidate(hazardAlertsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).setQuery(value);
                  },
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search Crag',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).setQuery('');
                            },
                          )
                        : null,
                  ),
                ),

                const SizedBox(height: 14),

                // 2. Horizontal State Filter Chips
                const FilterChipBar(),

                // 3. Active Hazard Alert Banner (Riverpod bound)
                alertsAsync.when(
                  data: (alerts) {
                    if (alerts.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: HazardAlertBanner(
                        alert: alerts.first,
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                // 4. Section: Popular Crags Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular Crags',
                      style: AppTextStyles.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        // Placeholder for full crag list navigation
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Popular Crags Horizontal List with State Handling
                cragsAsync.when(
                  loading: () => const SizedBox(
                    height: 220,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Container(
                    height: 120,
                    width: double.infinity,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading crags: $error',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (crags) {
                    if (crags.isEmpty) {
                      return const SizedBox(
                        height: 120,
                        child: Center(
                          child: Text(
                            'No items found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: crags.length,
                        itemBuilder: (context, index) {
                          final crag = crags[index];
                          return CragCard(
                            crag: crag,
                            onTap: () {
                              // Placeholder for Crag Detail navigation
                            },
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 5. Section: Recently Added Routes Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recently Added Routes',
                      style: AppTextStyles.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        // Placeholder for submitting a new route
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Recently Added Routes List with State Handling
                routesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (error, _) => Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading routes: $error',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: theme.colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (routes) {
                    if (routes.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            'No items found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: routes.length,
                      itemBuilder: (context, index) {
                        final route = routes[index];
                        return RouteItemCard(
                          route: route,
                          onTap: () {
                            // Placeholder for route detail navigation
                          },
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 6. Submit New Route CTA Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.go('/ticks');
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('SUBMIT NEW ROUTE'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                // Spacing to ensure content is fully scrollable above the floating action button & nav bar
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      );
  }
}
