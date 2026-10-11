import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crag.dart';
import '../models/hazard_alert.dart';
import '../util/hazard_type.dart';
import 'home_providers.dart';

/// Information definition for supported hazard types.
class HazardTypeOption {
  final String key; // Matches DB check: wasps, loose_rock, bad_bolt, other
  final String title;
  final String subtitle;
  final String iconEmoji;
  final String tag;

  const HazardTypeOption({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.iconEmoji,
    required this.tag,
  });
}



/// State model for the Hazard Reporting flow.
class HazardReportFormState {
  final String hazardType;
  final Crag? selectedCrag;
  final String sectorOrLocation;
  final String routeName;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final String description;
  final String? photoUrl;
  final bool isSubmitting;
  final String? errorMessage;
  final HazardAlert? submittedAlert;

  const HazardReportFormState({
    this.hazardType = 'loose_rock',
    this.selectedCrag,
    this.sectorOrLocation = '',
    this.routeName = '',
    this.severity = 'medium',
    this.description = '',
    this.photoUrl,
    this.isSubmitting = false,
    this.errorMessage,
    this.submittedAlert,
  });

  HazardType get currentHazardOption => HazardType.fromDb(hazardType);

  HazardReportFormState copyWith({
    String? hazardType,
    Crag? selectedCrag,
    bool clearCrag = false,
    String? sectorOrLocation,
    String? routeName,
    String? severity,
    String? description,
    String? photoUrl,
    bool clearPhoto = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    HazardAlert? submittedAlert,
    bool clearSubmittedAlert = false,
  }) {
    return HazardReportFormState(
      hazardType: hazardType ?? this.hazardType,
      selectedCrag: clearCrag ? null : (selectedCrag ?? this.selectedCrag),
      sectorOrLocation: sectorOrLocation ?? this.sectorOrLocation,
      routeName: routeName ?? this.routeName,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      submittedAlert: clearSubmittedAlert ? null : (submittedAlert ?? this.submittedAlert),
    );
  }
}

/// Notifier managing the state and submission of hazard reports.
class HazardReportFormNotifier extends Notifier<HazardReportFormState> {
  @override
  HazardReportFormState build() => const HazardReportFormState();

  void setHazardType(String type) {
    state = state.copyWith(hazardType: type, clearError: true);
  }

  void setSelectedCrag(Crag? crag) {
    state = state.copyWith(selectedCrag: crag, clearError: true);
  }

  void setSectorOrLocation(String location) {
    state = state.copyWith(sectorOrLocation: location);
  }

  void setRouteName(String name) {
    state = state.copyWith(routeName: name);
  }

  void setSeverity(String severity) {
    state = state.copyWith(severity: severity);
  }

  void setDescription(String desc) {
    state = state.copyWith(description: desc, clearError: true);
  }

  void setPhotoUrl(String? url) {
    state = state.copyWith(photoUrl: url);
  }

  /// Submits the hazard alert to Supabase or fallback local store,
  /// and updates Riverpod alert providers.
  Future<bool> submitReport() async {
  if (state.selectedCrag == null || !state.selectedCrag!.isOutdoor) {
    state = state.copyWith(
      errorMessage: 'Hazard alerts can only be reported for outdoor climbing crags.',
    );
    return false;
  }
  if (state.description.trim().isEmpty) {
    state = state.copyWith(errorMessage: 'Please enter a description of the hazard.');
    return false;
  }

  state = state.copyWith(isSubmitting: true, clearError: true);

  try {
    final client = Supabase.instance.client;
    final currentUserId = client.auth.currentUser?.id;

    await client.from('hazard_alerts').insert({
      'crag_id': state.selectedCrag!.id,
      'sector_id': null, // Set if a sector was specifically selected
      'route_id': null,  // Set if selected from known routes
      'user_id': currentUserId,
      'hazard_type': state.hazardType,
      'description': state.routeName.isNotEmpty 
          ? '[Route: ${state.routeName}] ${state.description.trim()}'
          : state.description.trim(),
      'status': 'active',
    });

    ref.invalidate(hazardAlertsProvider);
    state = state.copyWith(isSubmitting: false);
    return true;
  } catch (e) {
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: 'Failed to submit report: ${e.toString()}',
    );
    return false;
  }
}
  void reset() {
    state = const HazardReportFormState();
  }
}

/// Provider for managing Hazard Report form state.
final hazardReportFormProvider =
    NotifierProvider<HazardReportFormNotifier, HazardReportFormState>(
  HazardReportFormNotifier.new,
);

// Riverpod FutureProvider for fetching hazard alerts for a specific crag
final cragHazardsProvider =
    FutureProvider.family<List<HazardAlert>, String>((ref, cragId) async {
  try {
    final response = await Supabase.instance.client
        .from('hazard_alerts')  
      .select('*, sectors(name), routes(name)')
        .eq('sector_id', cragId)
        .eq('status', 'active')
        .order('created_at', ascending: false);
    final list = (response as List<dynamic>)
        .map((item) => HazardAlert.fromJson(item as Map<String, dynamic>))
        .toList();
        return list;
  } catch (e) {
    // Fallback gracefully if table is empty or error occurs
    return [];
  }
});



// Riverpod FutureProvider for fetching hazard alerts for a specific route
final routeHazardsProvider = 
    FutureProvider.family<List<HazardAlert>, String>((ref, routeId) async {
  try {
    final response = await Supabase.instance.client
        .from('hazard_alerts')
        .select('*, sectors(name), routes(name)')
        .eq('route_id', routeId)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    final list = (response as List<dynamic>)
        .map((item) => HazardAlert.fromJson(item as Map<String, dynamic>))
        .toList();

    return list;
  } catch (e) {
    // Fallback gracefully if table is empty or error occurs
    return [];
  }
});
  

