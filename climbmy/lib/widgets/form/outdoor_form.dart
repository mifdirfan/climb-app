import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/home_providers.dart';
import '../../providers/post_form_providers.dart';
import '../ascent_style_selector.dart';
import '../topo_video_card.dart';
import 'venue_picker_bottom_sheet.dart';

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

  void _handleSubmit() {
    final outdoorState = ref.read(outdoorPostFormProvider);
    final outdoorNotifier = ref.read(outdoorPostFormProvider.notifier);

    if (outdoorState.selectedCrag == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.hazardContainer,
          content: Text(
            'Please select a climbing crag or location first.',
            style: TextStyle(color: AppColors.hazardText),
          ),
        ),
      );
      return;
    }

    outdoorNotifier.setSubmitting(true);

    final sendData = {
      'type': 'outdoor',
      'crag_id': outdoorState.selectedCrag!.id,
      'crag_name': outdoorState.selectedCrag!.name,
      'route_name': _routeNameController.text.trim(),
      'ascent_style': outdoorState.ascentStyle,
      'date': outdoorState.date.toIso8601String(),
      'video_url': _videoUrlController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    widget.onPostSend?.call(sendData);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      outdoorNotifier.setSubmitting(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Send logged for ${outdoorState.selectedCrag!.name}! Keep crushing 🧗',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      widget.onSubmitted?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outdoorState = ref.watch(outdoorPostFormProvider);
    final outdoorNotifier = ref.read(outdoorPostFormProvider.notifier);
    final outdoorCragsAsync = ref.watch(outdoorCragsProvider);

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
                  return InkWell(
                    onTap: () => showVenuePickerSheet(
                      context: context,
                      title: 'Select Outdoor Crag',
                      venues: crags,
                      selectedVenueId: outdoorState.selectedCrag?.id,
                      onSelected: outdoorNotifier.setSelectedCrag,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      height: 52,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: outdoorState.selectedCrag != null
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              outdoorState.selectedCrag != null
                                  ? '${outdoorState.selectedCrag!.name} (${outdoorState.selectedCrag!.state})'
                                  : 'Select Climbing Area...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: outdoorState.selectedCrag != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: outdoorState.selectedCrag != null
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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

          // Section C: Route Name & Grade (Optional Details)
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ROUTE / PROBLEM NAME',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _routeNameController,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'e.g. Tak Boleh Tahan',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GRADE',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: outdoorState.grade,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceElevated,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                          items: const [
                            'V0', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6', 'V7', 'V8', 'V9', 'V10',
                            '5a', '5b', '5c', '6a', '6a+', '6b', '6b+', '6c', '7a', '7b', '7c', '8a'
                          ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (val) {
                            if (val != null) outdoorNotifier.setGrade(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
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
                  Text(
                    'Markdown supported',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
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

