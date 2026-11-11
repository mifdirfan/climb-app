import 'dart:async';

import 'package:climbmy/models/crag.dart';
import 'package:climbmy/providers/auth_providers.dart';
import 'package:climbmy/providers/logbook_providers.dart';
import 'package:climbmy/repositories/saved_crag_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../helpers/fixtures.dart';

/// In-memory stand-in for [SavedCragRepository].
class FakeSavedCragRepository implements SavedCragRepository {
  FakeSavedCragRepository(List<Crag> initial) : saved = [...initial];

  final List<Crag> saved;
  final List<String> calls = [];
  bool failWrites = false;

  /// When set, writes wait on this so tests can observe the optimistic state.
  Completer<void>? gate;

  @override
  Future<List<Crag>> getSavedCrags(String userId) async {
    calls.add('get:$userId');
    return [...saved];
  }

  @override
  Future<void> saveCrag({required String userId, required String cragId}) async {
    calls.add('save:$cragId');
    await gate?.future;
    if (failWrites) throw Exception('network down');
  }

  @override
  Future<void> unsaveCrag({required String userId, required String cragId}) async {
    calls.add('unsave:$cragId');
    await gate?.future;
    if (failWrites) throw Exception('network down');
  }
}

ProviderContainer makeContainer({User? user, required FakeSavedCragRepository repo}) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      currentUserProvider.overrideWithValue(user),
      savedCragRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('SavedCragsNotifier', () {
    test('guest resolves to empty list without hitting the repository', () async {
      final repo = FakeSavedCragRepository([cragBatuCaves]);
      final container = makeContainer(user: null, repo: repo);

      expect(await container.read(savedCragsProvider.future), isEmpty);
      expect(repo.calls, isEmpty);
    });

    test('loads the signed-in user\'s saved crags', () async {
      final repo = FakeSavedCragRepository([cragBatuCaves]);
      final container = makeContainer(user: testUser, repo: repo);

      final crags = await container.read(savedCragsProvider.future);
      expect(crags.map((c) => c.id), ['crag-1']);
      expect(repo.calls, ['get:${testUser.id}']);
    });

    test('toggle saves optimistically before the write completes', () async {
      final repo = FakeSavedCragRepository([])..gate = Completer<void>();
      final container = makeContainer(user: testUser, repo: repo);
      await container.read(savedCragsProvider.future);

      final pending = container.read(savedCragsProvider.notifier).toggle(cragBukitTabur);

      // UI already reflects the save while the network call is in flight.
      expect(container.read(isCragSavedProvider('crag-2')), isTrue);

      repo.gate!.complete();
      expect(await pending, isTrue);
      expect(repo.calls.last, 'save:crag-2');
    });

    test('toggle on a saved crag unsaves it', () async {
      final repo = FakeSavedCragRepository([cragBatuCaves, cragBukitTabur]);
      final container = makeContainer(user: testUser, repo: repo);
      await container.read(savedCragsProvider.future);

      final nowSaved = await container.read(savedCragsProvider.notifier).toggle(cragBatuCaves);

      expect(nowSaved, isFalse);
      expect(repo.calls.last, 'unsave:crag-1');
      expect(container.read(savedCragsProvider).value!.map((c) => c.id), ['crag-2']);
    });

    test('failed write rolls back to the previous list and rethrows', () async {
      final repo = FakeSavedCragRepository([cragBatuCaves])..failWrites = true;
      final container = makeContainer(user: testUser, repo: repo);
      await container.read(savedCragsProvider.future);

      await expectLater(
        container.read(savedCragsProvider.notifier).toggle(cragBukitTabur),
        throwsException,
      );

      expect(container.read(isCragSavedProvider('crag-2')), isFalse);
      expect(container.read(savedCragsProvider).value!.map((c) => c.id), ['crag-1']);
    });

    test('guest toggle throws StateError and never writes', () async {
      final repo = FakeSavedCragRepository([]);
      final container = makeContainer(user: null, repo: repo);
      await container.read(savedCragsProvider.future);

      expect(
        () => container.read(savedCragsProvider.notifier).toggle(cragBatuCaves),
        throwsStateError,
      );
      expect(repo.calls, isEmpty);
    });
  });
}
