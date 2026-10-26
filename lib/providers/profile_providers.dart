// lib/providers/profile_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../repositories/profile_repository.dart';
import 'auth_providers.dart';

/// Automatically loads the profile whenever the authenticated user changes.
///
/// - Intent: Reactively fetches the climber profile from Supabase when logged in.
/// - @source: [currentUserProvider] and `public.profiles` table.
/// - @sink: ProfileScreen and user account presentation.
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    debugPrint('--> [PROFILE:REPO] No authenticated user. Profile is null.');
    return null;
  }

  debugPrint('--> [PROFILE:REPO] Fetching profile record for UID: ${user.id}');
  try {
    final profile = await ref.watch(profileRepositoryProvider).getProfile(user.id);
    debugPrint('--> [PROFILE:REPO] Successfully resolved profile: username=${profile?.username}, display_name=${profile?.displayName}');
    return profile;
  } catch (e, st) {
    debugPrint('--> [PROFILE:REPO] 🛑 Failed to load profile: $e\n$st');
    return null;
  }
});