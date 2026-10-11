import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/home_providers.dart';
import '../../providers/post_form_providers.dart';
import '../ascent_style_selector.dart';
import '../topo_video_card.dart';
import 'crag_picker_bottom_sheet.dart';

/// Alias for phonetic foam / form naming
typedef OutdoorFoam = OutdoorForm;

/// Form for logging outdoor climbing sends and beta.
class OutdoorForm extends ConsumerStatefulWidget {
  final VoidCallback? onSubmitted;
  final ValueChanged<Map<String, dynamic>>? onPostSend;

  const OutdoorForm({
    super.key,
    this.onSubmitted,
    this.onPostSend,
  });

  @override
  ConsumerState<OutdoorForm> createState() => _OutdoorFormState();
}

class _OutdoorFormState extends ConsumerState<OutdoorForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _videoUrlController;
  late final TextEditingController _routeNameController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final outdoorState = ref.read(outdoorPostFormProvider);
    _videoUrlController = TextEditingController(text: outdoorState.videoUrl);
    _routeNameController = TextEditingController(text: outdoorState.routeName);
    _notesController = TextEditingController(text: outdoorState.notes);
  }

  @override
  void dispose() {
    _videoUrlController.dispose();
    _routeNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$mm / $dd / $yyyy';
  }

  Future<void> _pickDate() async {
    final theme = Theme.of(context);
    final outdoorState = ref.read(outdoorPostFormProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: outdoorState.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: AppColors.onPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      ref.read(outdoorPostFormProvider.notifier).setDate(picked);
    }
  }

  void _openVenuePicker(BuildContext context) {
    final outdoorState = ref.read(outdoorPostFormProvider);
    final outdoorNotifier = ref.read(outdoorPostFormProvider.notifier);
    final crags = ref.read(outdoorCragsProvider).value ?? ref.read(cragsProvider).value ?? [];
    final outdoorVenues = crags.where((c) => c.isOutdoor).toList();

    showVenuePickerSheet(
      context: context,
      title: 'Select Crag & Route',
      venues: outdoorVenues,
      outdoorOnly: true,
      selectedVenueId: outdoorState.selectedCrag?.id,
      selectedRouteId: outdoorState.selectedRouteId,
      onSelected: (crag) {
        outdoorNotifier.setSelectedCrag(crag);
      },
      onRouteSelected: (route) {
        if (route != null) {
          outdoorNotifier.setSelectedRouteId(route.id);
          outdoorNotifier.setRouteName(route.name);
          _routeNameController.text = route.name;
          if (route.grade.isNotEmpty) {
            outdoorNotifier.setGrade(route.grade);
          }
          if (route.routeType.isNotEmpty) {
            outdoorNotifier.setRouteType(route.routeType);
          }
        } else {
          outdoorNotifier.setSelectedRouteId(null);
        }
      },
    );
  }

  Future<void> _handleSubmit() async {
  final outdoorState = ref.read(outdoorPostFormProvider);
  final outdoorNotifier = ref.read(outdoorPostFormProvider.notifier);
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;

  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to log outdoor sends.')),
    );
    return;
  }

  if (outdoorState.selectedRouteId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a verified route from the database.')),
    );
    return;
  }

  outdoorNotifier.setSubmitting(true);

  try {
    // Convert UI ascent style to valid check constraint enum
    String tickType = outdoorState.ascentStyle.toLowerCase();
    if (tickType == 'redpoint') tickType = 'send';

    await client.from('ticks').insert({
      'user_id': user.id,
      'route_id': outdoorState.selectedRouteId,
      'tick_type': tickType,
      'video_url': _videoUrlController.text.trim().isNotEmpty 
          ? _videoUrlController.text.trim() 
          : null,
      'notes': _notesController.text.trim(),
      'climbed_at': outdoorState.date.toIso8601String().split('T').first,
    });

    if (!mounted) return;
    outdoorNotifier.setSubmitting(false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Send logged for ${outdoorState.routeName}!'),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
    widget.onSubmitted?.call();
  } catch (e) {
    if (!mounted) return;
    outdoorNotifier.setSubmitting(false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to log send: $e'),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outdoorState = ref.watch(outdoorPostFormProvider);
    final outdoorNotifier = ref.read(outdoorPostFormProvider.notifier);
    final outdoorCragsAsync = ref.watch(outdoorCragsProvider);

    ref.listen<OutdoorPostFormState>(outdoorPostFormProvider, (prev, next) {
      if (prev?.routeName != next.routeName &&
          _routeNameController.text != next.routeName) {
        _routeNameController.text = next.routeName;
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('outdoor_form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section A: Hero Media / Topo Video Card
          TopoVideoCard(
            controller: _videoUrlController,
          ),

          const SizedBox(height: 20),

          // Section B: Crag & Location Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT CRAG / LOCATION *',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              outdoorCragsAsync.when(
                loading: () => Container(
                  height: 52,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading crags...',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                error: (err, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: theme.colorScheme.error),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error loading crags',
                          style: AppTextStyles.bodySmall.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.refresh(cragsProvider),
                        child: const Text('Retry', style: TextStyle(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                data: (crags) {
                  final isSelected = outdoorState.selectedCrag != null;
                  final hasRoute = isSelected && outdoorState.routeName.isNotEmpty;

                  return InkWell(
                    key: const Key('crag_picker_trigger'),
                    onTap: () => _openVenuePicker(context),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 52),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: isSelected ? AppColors.primary : AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isSelected
                                      ? '${outdoorState.selectedCrag!.name} (${outdoorState.selectedCrag!.state})'
                                      : 'Select Climbing Area & Route...',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.textPrimary
                                        : AppColors.textMuted,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (hasRoute) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.route_outlined,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Route: ${outdoorState.routeName} • ${outdoorState.grade}',
                                          style: AppTextStyles.caption.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

         

          // Section D: Ascent Style / Status Pills
          AscentStyleSelector(
            selectedStyle: outdoorState.ascentStyle,
            onSelected: outdoorNotifier.setAscentStyle,
          ),

          const SizedBox(height: 20),

          // Section E: Date of Climb
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DATE OF CLIMB',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  height: 52,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDate(outdoorState.date),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.edit_calendar_rounded,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Section F: Beta, Conditions & Crux Notes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BETA, CONDITIONS & CRUX',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                minLines: 3,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Crux sequence, weather conditions, micro-beta, gear used...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Section G: Submit CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: outdoorState.isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: outdoorState.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'POST SEND',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.onPrimary,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

