import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/indoor_session.dart';
import '../../providers/home_providers.dart';
import '../../providers/post_form_providers.dart';
import '../felt_grade_selector.dart';
import '../session_rating_bar.dart';
import 'venue_picker_bottom_sheet.dart';

/// Alias for phonetic foam / form naming
typedef IndoorFoam = IndoorForm;

/// Form for logging indoor bouldering and training gym sessions.
class IndoorForm extends ConsumerStatefulWidget {
  final VoidCallback? onSubmitted;
  final ValueChanged<Map<String, dynamic>>? onPostSend;

  const IndoorForm({
    super.key,
    this.onSubmitted,
    this.onPostSend,
  });

  @override
  ConsumerState<IndoorForm> createState() => _IndoorFormState();
}

class _IndoorFormState extends ConsumerState<IndoorForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;

  static const List<int> _durationOptions = [30, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    final indoorState = ref.read(indoorSessionFormProvider);
    _notesController = TextEditingController(text: indoorState.notes);
  }

  @override
  void dispose() {
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
    final indoorState = ref.read(indoorSessionFormProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: indoorState.sessionDate,
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
      ref.read(indoorSessionFormProvider.notifier).setSessionDate(picked);
    }
  }

  void _handleSubmit() {
    final indoorState = ref.read(indoorSessionFormProvider);
    final indoorNotifier = ref.read(indoorSessionFormProvider.notifier);

    if (indoorState.selectedGym == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.hazardContainer,
          content: Text(
            'Please select a climbing gym first.',
            style: TextStyle(color: AppColors.hazardText),
          ),
        ),
      );
      return;
    }

    indoorNotifier.setSubmitting(true);

    final session = IndoorSession(
      id: 'session-${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current-user',
      gymId: indoorState.selectedGym!.id,
      sessionDate: indoorState.sessionDate,
      durationMinutes: indoorState.durationMinutes,
      feltGrade: indoorState.feltGrade,
      rating: indoorState.rating,
      notes: _notesController.text.trim(),
      // gradeTallies: indoorState.gradeTallies,
      gymName: indoorState.selectedGym!.name,
    );

    final sessionData = {
      'type': 'indoor',
      ...session.toJson(),
      'gym_name': indoorState.selectedGym!.name,
      'total_sends': indoorState.totalSends,
    };

    widget.onPostSend?.call(sessionData);

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      indoorNotifier.setSubmitting(false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Row(
            children: [
              const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Indoor session at ${indoorState.selectedGym!.name} logged! (${indoorState.totalSends} sends)',
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
    final indoorState = ref.watch(indoorSessionFormProvider);
    final indoorNotifier = ref.read(indoorSessionFormProvider.notifier);
    final indoorGymsAsync = ref.watch(indoorGymsProvider);

    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('indoor_form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Gym Venue Selection
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SELECT CLIMBING GYM *',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              indoorGymsAsync.when(
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
                        'Loading gyms...',
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
                          'Error loading gyms',
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
                data: (gyms) {
                  return InkWell(
                    onTap: () => showVenuePickerSheet(
                      context: context,
                      title: 'Select Climbing Gym',
                      venues: gyms,
                      selectedVenueId: indoorState.selectedGym?.id,
                      onSelected: indoorNotifier.setSelectedGym,
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
                          color: indoorState.selectedGym != null
                              ? AppColors.primary.withValues(alpha: 0.6)
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.fitness_center_rounded,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              indoorState.selectedGym != null
                                  ? '${indoorState.selectedGym!.name} (${indoorState.selectedGym!.state})'
                                  : 'Select Climbing Gym...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: indoorState.selectedGym != null
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                                fontWeight: indoorState.selectedGym != null
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

          // Section 2: Date & Session Duration
          Row(
            children: [
              // Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SESSION DATE',
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
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _formatDate(indoorState.sessionDate),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DURATION (MIN)',
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
                        child: DropdownButton<int>(
                          value: indoorState.durationMinutes,
                          isExpanded: true,
                          dropdownColor: AppColors.surfaceElevated,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                          items: _durationOptions
                              .map(
                                (mins) => DropdownMenuItem(
                                  value: mins,
                                  child: Text('$mins mins'),
                                ),
                              )
                              .toList(),
                          onChanged: indoorNotifier.setDurationMinutes,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Section 3: Boulder Sends Tally Counter
          // IndoorTallyCounter(
          //   tallies: indoorState.gradeTallies,
          //   onIncrement: indoorNotifier.incrementTally,
          //   onDecrement: indoorNotifier.decrementTally,
          // ),

          // const SizedBox(height: 20),

          // Section 4: Felt Grade / Perceived Effort
          FeltGradeSelector(
            selectedFeltGrade: indoorState.feltGrade,
            onSelected: indoorNotifier.setFeltGrade,
          ),

          const SizedBox(height: 20),

          // Section 5: Session Rating (1 - 5 Stars)
          SessionRatingBar(
            rating: indoorState.rating,
            onRatingChanged: indoorNotifier.setRating,
          ),

          const SizedBox(height: 20),

          // Section 6: Training & Session Notes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SESSION NOTES & DRILLS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Training focus, drills completed, fatigue levels...',
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

          // Section 7: Submit CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: indoorState.isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: indoorState.isSubmitting
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
                          'LOG GYM SESSION',
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

