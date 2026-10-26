import 'package:climbmy/models/crag.dart';
import 'package:climbmy/providers/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../repositories/session_repository.dart';
import '../repositories/tick_repository.dart';
import 'auth_providers.dart';
import '../models/indoor_session.dart';


/// Supported modes for logging climbing sends in PostScreen.
enum ClimbPostType {
  outdoor,
  indoor,
}

/// Controls whether the user is logging an Outdoor send or an Indoor gym session.
class PostTypeNotifier extends Notifier<ClimbPostType> {
  @override
  ClimbPostType build() => ClimbPostType.outdoor;

  void setType(ClimbPostType type) {
    state = type;
  }
}

final postTypeProvider = NotifierProvider<PostTypeNotifier, ClimbPostType>(
  PostTypeNotifier.new,
);

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final monthlyIndoorSessionsProvider = FutureProvider<List<IndoorSession>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(sessionRepositoryProvider).getMonthlySessions(user.id, month);
});

/// State for the Outdoor send logging form.
class OutdoorPostFormState {
  final Crag? selectedCrag;
  final String? selectedRouteId;
  final String routeName;
  final String grade;
  final String routeType; // 'boulder' | 'sport' | 'trad'
  final String ascentStyle; // 'redpoint' | 'flash' | 'onsight' | 'repeat' | 'project'
  final DateTime date;
  final String videoUrl;
  final String notes;
  final bool isSubmitting;

  OutdoorPostFormState({
    this.selectedCrag,
    this.selectedRouteId,
    this.routeName = '',
    this.grade = 'V3',
    this.routeType = 'boulder',
    this.ascentStyle = 'redpoint',
    DateTime? date,
    this.videoUrl = '',
    this.notes = '',
    this.isSubmitting = false,
  }) : date = date ?? DateTime.now();

  OutdoorPostFormState copyWith({
    Crag? selectedCrag,
    bool clearCrag = false,
    String? selectedRouteId,
    bool clearRouteId = false,
    String? routeName,
    String? grade,
    String? routeType,
    String? ascentStyle,
    DateTime? date,
    String? videoUrl,
    String? notes,
    bool? isSubmitting,
  }) {
    return OutdoorPostFormState(
      selectedCrag: clearCrag ? null : (selectedCrag ?? this.selectedCrag),
      selectedRouteId:
          clearRouteId ? null : (selectedRouteId ?? this.selectedRouteId),
      routeName: routeName ?? this.routeName,
      grade: grade ?? this.grade,
      routeType: routeType ?? this.routeType,
      ascentStyle: ascentStyle ?? this.ascentStyle,
      date: date ?? this.date,
      videoUrl: videoUrl ?? this.videoUrl,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Notifier handling mutations for the Outdoor send form.
class OutdoorPostFormNotifier extends Notifier<OutdoorPostFormState> {
  @override
  OutdoorPostFormState build() => OutdoorPostFormState();

  void setSelectedCrag(Crag? crag) {
    if (crag?.id != state.selectedCrag?.id) {
      state = state.copyWith(
        selectedCrag: crag,
        clearRouteId: true,
      );
    } else {
      state = state.copyWith(selectedCrag: crag);
    }
  }

  void setSelectedRouteId(String? routeId) {
    state = state.copyWith(
      selectedRouteId: routeId,
      clearRouteId: routeId == null,
    );
  }

  void setRouteName(String name) {
    state = state.copyWith(routeName: name);
  }

  void setGrade(String grade) {
    state = state.copyWith(grade: grade);
  }

  void setRouteType(String routeType) {
    state = state.copyWith(routeType: routeType);
  }

  void setAscentStyle(String style) {
    state = state.copyWith(ascentStyle: style);
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date);
  }

  void setVideoUrl(String url) {
    state = state.copyWith(videoUrl: url);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  void reset() {
    state = OutdoorPostFormState();
  }
  Future<void> submitForm() async {
    if (state.selectedRouteId == null) throw Exception('No route selected.');
    
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('You must be signed in to log outdoor sends.');

    state = state.copyWith(isSubmitting: true);
    debugPrint('--> [TICKS:STATE] Mutating state to AsyncLoading for tick submission');

    try {
      String tickType = state.ascentStyle.toLowerCase();
      if (tickType == 'redpoint') tickType = 'send';

      await ref.read(tickRepositoryProvider).createTick({
        'user_id': user.id,
        'route_id': state.selectedRouteId,
        'tick_type': tickType,
        'video_url': state.videoUrl.trim().isNotEmpty ? state.videoUrl.trim() : null,
        'notes': state.notes.trim(),
        'climbed_at': state.date.toIso8601String().split('T').first,
      });
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
  
}

final outdoorPostFormProvider =
    NotifierProvider<OutdoorPostFormNotifier, OutdoorPostFormState>(
  OutdoorPostFormNotifier.new,
);

/// State for the Indoor gym session logging form (public.indoor_sessions).
class IndoorSessionFormState {
  final Crag? selectedGym;
  final DateTime sessionDate;
  final int? durationMinutes;
  final String? feltGrade; // 'easy' | 'average' | 'hard' | 'limit'
  final int? rating; // 1 to 5
  final Map<String, int> gradeTallies;
  final String notes;
  final bool isSubmitting;

  IndoorSessionFormState({
    this.selectedGym,
    DateTime? sessionDate,
    this.durationMinutes = 90,
    this.feltGrade,
    this.rating = 4,
    Map<String, int>? gradeTallies,
    this.notes = '',
    this.isSubmitting = false,
  })  : sessionDate = sessionDate ?? DateTime.now(),
        gradeTallies = gradeTallies ??
            {
              'V0': 0,
              'V1': 0,
              'V2': 0,
              'V3': 0,
              'V4': 0,
              'V5': 0,
              'V6+': 0,
            };

  int get totalSends => gradeTallies.values.fold(0, (sum, count) => sum + count);

  IndoorSessionFormState copyWith({
    Crag? selectedGym,
    bool clearGym = false,
    DateTime? sessionDate,
    int? durationMinutes,
    bool clearDuration = false,
    String? feltGrade,
    bool clearFeltGrade = false,
    int? rating,
    bool clearRating = false,
    Map<String, int>? gradeTallies,
    String? notes,
    bool? isSubmitting,
  }) {
    return IndoorSessionFormState(
      selectedGym: clearGym ? null : (selectedGym ?? this.selectedGym),
      sessionDate: sessionDate ?? this.sessionDate,
      durationMinutes: clearDuration ? null : (durationMinutes ?? this.durationMinutes),
      feltGrade: clearFeltGrade ? null : (feltGrade ?? this.feltGrade),
      rating: clearRating ? null : (rating ?? this.rating),
      gradeTallies: gradeTallies ?? this.gradeTallies,
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// Notifier handling mutations for the Indoor gym session form.
class IndoorSessionFormNotifier extends Notifier<IndoorSessionFormState> {
  @override
  IndoorSessionFormState build() => IndoorSessionFormState();

  void setSelectedGym(Crag? gym) {
    final defaultTallies = <String, int>{};
    if (gym != null && gym.gradingScale.isNotEmpty) {
      for (final tag in gym.gradingScale) {
        defaultTallies[tag.label] = 0;
      }
    } else {
      defaultTallies.addAll({
        'V0': 0,
        'V1': 0,
        'V2': 0,
        'V3': 0,
        'V4': 0,
        'V5': 0,
        'V6+': 0,
      });
    }

    state = state.copyWith(
      selectedGym: gym,
      gradeTallies: defaultTallies,
    );
  }

  void setSessionDate(DateTime date) {
    state = state.copyWith(sessionDate: date);
  }

  void setDurationMinutes(int? minutes) {
    state = state.copyWith(durationMinutes: minutes);
  }

  void setFeltGrade(String? feltGrade) {
    state = state.copyWith(feltGrade: feltGrade);
  }

  void setRating(int? rating) {
    state = state.copyWith(rating: rating);
  }

  void incrementTally(String grade) {
    final updated = Map<String, int>.from(state.gradeTallies);
    updated[grade] = (updated[grade] ?? 0) + 1;
    state = state.copyWith(gradeTallies: updated);
  }

  void decrementTally(String grade) {
    final updated = Map<String, int>.from(state.gradeTallies);
    final current = updated[grade] ?? 0;
    if (current > 0) {
      updated[grade] = current - 1;
      state = state.copyWith(gradeTallies: updated);
    }
  }

  void setGradeTally(String grade, int count) {
    final updated = Map<String, int>.from(state.gradeTallies);
    updated[grade] = count.clamp(0, 999);
    state = state.copyWith(gradeTallies: updated);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  void reset() {
    state = IndoorSessionFormState();
  }
  Future<void> submitForm() async {
    if (state.selectedGym == null) throw Exception('No gym selected.');
    
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('You must be signed in to log gym sessions.');

    state = state.copyWith(isSubmitting: true);
    debugPrint('--> [SESSION:STATE] Mutating state to AsyncLoading for session submission');

    try {
      await ref.read(sessionRepositoryProvider).createIndoorSession({
        'user_id': user.id,
        'gym_id': state.selectedGym!.id,
        'session_date': state.sessionDate.toIso8601String().split('T').first,
        'duration_minutes': state.durationMinutes,
        'felt_grade': state.feltGrade,
        'rating': state.rating,
        'grade_tallies': state.gradeTallies,
        'notes': state.notes.trim(),
      });
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }
}

final indoorSessionFormProvider =
    NotifierProvider<IndoorSessionFormNotifier, IndoorSessionFormState>(
  IndoorSessionFormNotifier.new,
);

/// Convenience provider returning only outdoor crags
final outdoorCragsProvider = Provider<AsyncValue<List<Crag>>>((ref) {
  final allCrags = ref.watch(cragsProvider);
  return allCrags.whenData((crags) {
    final filtered = crags.where((c) => c.isOutdoor).toList();
    return filtered.isNotEmpty ? filtered : crags;
  });
});

/// Convenience provider returning indoor climbing gyms
final indoorGymsProvider = Provider<AsyncValue<List<Crag>>>((ref) {
  final allCrags = ref.watch(cragsProvider);
  return allCrags.whenData((crags) {
    final filtered = crags.where((c) => c.isIndoor).toList();
    return filtered.isNotEmpty ? filtered : crags;
  });
});

