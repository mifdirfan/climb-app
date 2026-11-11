// lib/providers/logbook_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/crag.dart';
import '../models/tick.dart';
import '../repositories/saved_crag_repository.dart';
import '../repositories/tick_repository.dart';
import 'auth_providers.dart';

/// The signed-in climber's own tick log (newest first).
///
/// Watches [currentUserProvider], so it re-fetches automatically on login,
/// logout or account switch. Guests resolve to an empty list.
///
/// @source PostgreSQL:ticks (filtered by auth user id)
/// @sink   TickHistoryScreen
final myTicksProvider = FutureProvider<List<Tick>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    debugPrint('--> [LOGBOOK:STATE] No user; tick log is empty');
    return const [];
  }
  debugPrint('--> [LOGBOOK:STATE] Loading tick log for ${user.id}');
  return ref.watch(tickRepositoryProvider).getTicksForUser(user.id);
});

/// The signed-in climber's bookmarked crags, with optimistic toggle.
///
/// An [AsyncNotifier] (rather than a FutureProvider + invalidate) so the
/// bookmark icon flips instantly and rolls back if the write fails, without a
/// full list re-fetch.
///
/// @source PostgreSQL:saved_crags ⨝ crags
/// @sink   SavedCragsScreen, CragDetailScreen bookmark icon
class SavedCragsNotifier extends AsyncNotifier<List<Crag>> {
  @override
  Future<List<Crag>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      debugPrint('--> [SAVED_CRAGS:STATE] No user; saved crags empty');
      return const [];
    }
    debugPrint('--> [SAVED_CRAGS:STATE] Loading saved crags for ${user.id}');
    return ref.watch(savedCragRepositoryProvider).getSavedCrags(user.id);
  }

  /// Saves [crag] if not saved, otherwise removes it. Returns the new saved state.
  ///
  /// Throws [StateError] for guests; rethrows repository errors after
  /// restoring the previous list.
  Future<bool> toggle(Crag crag) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Sign in required to save crags.');

    final previous = state.value ?? const <Crag>[];
    final wasSaved = previous.any((c) => c.id == crag.id);

    debugPrint('--> [SAVED_CRAGS:STATE] Optimistic ${wasSaved ? 'unsave' : 'save'} of ${crag.id}');
    state = AsyncData(
      wasSaved ? previous.where((c) => c.id != crag.id).toList() : [crag, ...previous],
    );

    try {
      final repo = ref.read(savedCragRepositoryProvider);
      if (wasSaved) {
        await repo.unsaveCrag(userId: user.id, cragId: crag.id);
      } else {
        await repo.saveCrag(userId: user.id, cragId: crag.id);
      }
      return !wasSaved;
    } catch (e) {
      debugPrint('--> [SAVED_CRAGS:STATE] Toggle failed, rolling back: $e');
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final savedCragsProvider =
    AsyncNotifierProvider<SavedCragsNotifier, List<Crag>>(SavedCragsNotifier.new);

/// Whether [cragId] is in the current user's saved list (false while loading).
final isCragSavedProvider = Provider.family<bool, String>((ref, cragId) {
  return ref.watch(savedCragsProvider).value?.any((c) => c.id == cragId) ?? false;
});
