import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
              primary: context.palette.primary,
              onPrimary: context.palette.onPrimary,
              surface: context.palette.surface,
              onSurface: context.palette.textPrimary,
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

    if (outdoorState.selectedRouteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a verified route from the database.')),
      );
      return;
    }

    // Sync notes and video URL from controllers before submitting
    outdoorNotifier.setNotes(_notesController.text.trim());
    outdoorNotifier.setVideoUrl(_videoUrlController.text.trim());
    debugPrint('--> [TICKS:UI] User submitted outdoor tick form');

    try {
      await outdoorNotifier.submitForm();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Send logged for ${outdoorState.routeName}!'),
          backgroundColor: context.palette.surfaceElevated,
        ),
      );
      widget.onSubmitted?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
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
                style: context.textStyles.labelSmall.copyWith(
                  color: context.palette.textMuted,
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
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.palette.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Loading crags...',
                        style: context.textStyles.bodySmall.copyWith(color: context.palette.textMuted),
                      ),
                    ],
                  ),
                ),
                error: (err, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.palette.surface,
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
                          style: context.textStyles.bodySmall.copyWith(color: theme.colorScheme.error),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.refresh(cragsProvider),
                        child: Text('Retry', style: context.textStyles.labelMedium.copyWith(color: context.palette.accent)),
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
                        color: context.palette.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: isSelected
                              ? context.palette.accent.withValues(alpha: 0.6)
                              : context.palette.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: isSelected ? context.palette.accent : context.palette.textMuted,
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
                                  style: context.textStyles.bodyMedium.copyWith(
                                    color: isSelected
                                        ? context.palette.textPrimary
                                        : context.palette.textMuted,
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
                                      Icon(
                                        Icons.route_outlined,
                                        size: 14,
                                        color: context.palette.accent,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          'Route: ${outdoorState.routeName} • ${outdoorState.grade}',
                                          style: context.textStyles.caption.copyWith(
                                            color: context.palette.textSecondary,
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
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: context.palette.textMuted,
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
                style: context.textStyles.labelSmall.copyWith(
                  color: context.palette.textMuted,
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
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: context.palette.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: context.palette.textMuted,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDate(outdoorState.date),
                          style: context.textStyles.bodyMedium.copyWith(
                            color: context.palette.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.edit_calendar_rounded,
                        size: 18,
                        color: context.palette.textMuted,
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
                    style: context.textStyles.labelSmall.copyWith(
                      color: context.palette.textMuted,
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
                style: context.textStyles.bodyMedium.copyWith(color: context.palette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Crux sequence, weather conditions, micro-beta, gear used...',
                  hintStyle: context.textStyles.bodySmall.copyWith(
                    color: context.palette.textMuted,
                    height: 1.4,
                  ),
                  filled: true,
                  fillColor: context.palette.surface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: context.palette.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide(color: context.palette.borderSubtle),
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
                backgroundColor: context.palette.primary,
                foregroundColor: context.palette.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: outdoorState.isSubmitting
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.palette.onPrimary,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'POST SEND',
                          style: context.textStyles.titleSmall.copyWith(
                            color: context.palette.onPrimary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: context.palette.onPrimary,
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

