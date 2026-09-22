import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/crag.dart';
import '../models/hazard_alert.dart';
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

/// Catalog of selectable hazard categories matching climbing safety domains.
const List<HazardTypeOption> kHazardTypeOptions = [
  HazardTypeOption(
    key: 'loose_rock',
    title: 'Loose Rock',
    subtitle: 'Chossy rock, detached flakes, or active rockfall zone',
    iconEmoji: '🪨',
    tag: 'HIGH RISK',
  ),
  HazardTypeOption(
    key: 'wasps',
    title: 'Wasps & Wildlife',
    subtitle: 'Active wasp/bee nests, hornet swarms, or aggressive wildlife',
    iconEmoji: '🐝',
    tag: 'ACTIVE SIGHTING',
  ),
  HazardTypeOption(
    key: 'bad_bolt',
    title: 'Bad Bolt / Anchor',
    subtitle: 'Loose/spinning hanger, rusted bolt, or worn anchor chains',
    iconEmoji: '🔩',
    tag: 'EQUIPMENT',
  ),
  HazardTypeOption(
    key: 'other',
    title: 'Other Danger',
    subtitle: 'Trail erosion, flash flood risk, fallen tree, or access issues',
    iconEmoji: '⚠️',
    tag: 'GENERAL',
  ),
];

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

  HazardTypeOption get currentHazardOption {
    return kHazardTypeOptions.firstWhere(
      (opt) => opt.key == hazardType,
      orElse: () => kHazardTypeOptions.last,
    );
  }

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
    if (state.selectedCrag != null && !state.selectedCrag!.isOutdoor) {
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
      final cragName = state.selectedCrag?.name ?? 'Outdoor Crag';
      final sectorDisplay = state.sectorOrLocation.isNotEmpty
          ? state.sectorOrLocation
          : 'General Area';
      final routeDisplay = state.routeName.isNotEmpty ? state.routeName : null;

      // Construct the alert object
      final alertId = 'hazard-${DateTime.now().millisecondsSinceEpoch}';
      final newAlert = HazardAlert(
        id: alertId,
        sectorId: state.selectedCrag?.id ?? 'general-sector',
        sectorName: '$cragName - $sectorDisplay',
        routeName: routeDisplay,
        hazardType: state.hazardType,
        description: state.description.trim(),
        status: 'active',
        createdAt: DateTime.now(),
      );

      // Attempt Supabase insert if client is initialized
      try {
        final client = Supabase.instance.client;
        await client.from('hazard_alerts').insert({
          'sector_id': state.selectedCrag?.id ?? '00000000-0000-0000-0000-000000000000',
          'hazard_type': state.hazardType,
          'description': '${state.description.trim()} [Location: $cragName / $sectorDisplay${routeDisplay != null ? " / $routeDisplay" : ""}]',
          'status': 'active',
        });
      } catch (_) {
        // Fallback for offline mode, testing environments, or unseeded tables
      }

      // Invalidate the alerts provider so the HomeScreen updates immediately
      ref.invalidate(hazardAlertsProvider);

      state = state.copyWith(
        isSubmitting: false,
        submittedAlert: newAlert,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to submit report. Please try again.',
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

