// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/home_providers.dart';
import '../../widgets/crag_card.dart';
import '../../widgets/route_item_card.dart';
import '../../widgets/hazard_alert_banner.dart';
import '../../widgets/filter_chip_bar.dart';

/// Main Home screen of ClimbApp matching the Figma 'Home' frame (Node 5315:2).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
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
      // Top Navigation App Bar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            // Placeholder for navigation drawer or menu
          },
        ),
        title: Text(
          'Crag',
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: 28,
            color: AppColors.primaryContainer,
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
      ),

      // Responsive Flex Auto-Layout Body
      body: SafeArea(
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

                const SizedBox(height: 12),

                // 3. Active Hazard Alert Banner (Riverpod bound)
                alertsAsync.when(
                  data: (alerts) {
                    if (alerts.isEmpty) {
                      // Placeholder hazard alert if table has no active records yet
                      return const HazardAlertBanner(
                        customMessage: '⚠️ Wasps reported at Damai Wall',
                      );
                    }
                    return HazardAlertBanner(
                      alert: alerts.first,
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
                        Icons.filter_list_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        // Placeholder for route filters
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
                      // Placeholder for submit new route
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('SUBMIT NEW ROUTE'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),

      // Bottom Navigation Bar (Figma BottomNavBar)
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Crags',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline_rounded),
            activeIcon: Icon(Icons.check_circle_rounded),
            label: 'Ticks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
