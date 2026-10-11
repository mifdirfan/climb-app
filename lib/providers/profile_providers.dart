// lib/providers/profile_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/supabase_provider.dart';
import '../models/profile.dart';
import '../repositories/profile_repository.dart';

/// Automatically loads the profile whenever the authenticated user changes
final currentProfileProvider = FutureProvider<Profile?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});