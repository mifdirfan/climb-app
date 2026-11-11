import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_router.dart';
import '../models/crag.dart';
import '../providers/auth_providers.dart';
import '../providers/logbook_providers.dart';
import '../widgets/auth_required_view.dart';
import 'crags_list_screen.dart';

/// Profile > "Saved Crags & Topos": only the crags the signed-in user bookmarked.
///
/// Reuses [VenuesListScreen] (search, empty/error states) with
/// [savedCragsProvider] as its source. Guests see [AuthRequiredView].
class SavedCragsScreen extends ConsumerWidget {
  const SavedCragsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    if (!isAuthenticated) {
      return const AuthRequiredView(
        title: 'Your Saved Crags',
        subtitle: 'Sign in to bookmark crags and keep their topos handy.',
        redirectPath: AppRoutes.savedCrags,
        icon: Icons.bookmark_border_rounded,
        showAppBar: true,
      );
    }

    return VenuesListScreen(
      title: 'Saved Crags & Topos',
      venuesSource: savedCragsProvider,
      showCategoryFilter: false, // bookmarks are outdoor crags only
      emptyMessage: 'No saved crags yet',
      emptySubtitle: 'Tap the bookmark icon on any crag to save it here.',
      emptyIcon: Icons.bookmark_border_rounded,
      onVenueTap: (Crag crag) {
        debugPrint('--> [SAVED_CRAGS:UI] Open saved crag ${crag.id}');
        context.push(AppRoutes.cragDetailPath(crag.id), extra: crag);
      },
    );
  }
}
