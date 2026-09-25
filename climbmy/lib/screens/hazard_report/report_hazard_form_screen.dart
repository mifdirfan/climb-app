import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/crag.dart';
import '../../providers/hazard_report_providers.dart';
import '../../providers/home_providers.dart';
import '../../util/auth_guard.dart';
import '../../widgets/form/crag_picker_bottom_sheet.dart';

class ReportHazardFormScreen extends ConsumerStatefulWidget {
  const ReportHazardFormScreen({super.key});

  @override
  ConsumerState<ReportHazardFormScreen> createState() =>
      _ReportHazardFormScreenState();
}

class _ReportHazardFormScreenState
    extends ConsumerState<ReportHazardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sectorController;
  late final TextEditingController _routeController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(hazardReportFormProvider);
    _sectorController = TextEditingController(text: state.sectorOrLocation);
    _routeController = TextEditingController(text: state.routeName);
    _descriptionController = TextEditingController(text: state.description);
  }

  @override
  void dispose() {
    _sectorController.dispose();
    _routeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    // 1. Ensure user is authenticated before writing to the database
    requireAuth(
      context,
      ref,
      reason: 'Please sign in to submit a hazard report.',
      action: () async {
        final formState = ref.read(hazardReportFormProvider);

        if (formState.selectedCrag == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(
                'Please select an outdoor climbing crag first.',
                style: TextStyle(color: Theme.of(context).colorScheme.onError),
              ),
            ),
          );
          return;
        }

        if (!_formKey.currentState!.validate()) return;

        final formNotifier = ref.read(hazardReportFormProvider.notifier);
        formNotifier.setSectorOrLocation(_sectorController.text.trim());
        formNotifier.setRouteName(_routeController.text.trim());
        formNotifier.setDescription(_descriptionController.text.trim());

        final success = await formNotifier.submitReport();
        if (success && mounted) {
          context.pushReplacement(AppRoutes.reportHazardConfirmation);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formState = ref.watch(hazardReportFormProvider);
    final formNotifier = ref.read(hazardReportFormProvider.notifier);
    final cragsAsync = ref.watch(cragsProvider);
    final currentOption = formState.currentHazardOption;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: colorScheme.onSurface,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.reportHazardSelect);
            }
          },
        ),
        title: Text(
          'HAZARD DETAILS',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Selected Hazard Category Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? AppColors.surface,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          currentOption.iconEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Category',
                              style: AppTextStyles.caption.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              currentOption.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.reportHazardSelect);
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'CHANGE',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Outdoor Crag Picker
                Text(
                  'OUTDOOR CLIMBING CRAG *',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    final allVenues = cragsAsync.value ?? [];
                    final outdoorVenues =
                        allVenues.where((c) => c.isOutdoor).toList();

                    showVenuePickerSheet(
                      context: context,
                      title: 'Select Outdoor Crag',
                      venues: outdoorVenues,
                      outdoorOnly: true,
                      selectedVenueId: formState.selectedCrag?.id,
                      onSelected: (crag) {
                        if (crag.id != formState.selectedCrag?.id) {
                          formNotifier.setSelectedCrag(crag);
                          formNotifier.setRouteName('');
                          formNotifier.setSectorOrLocation('');
                          _routeController.clear();
                          _sectorController.clear();
                        }
                      },
                      onRouteSelected: (route) {
                        if (route != null) {
                          formNotifier.setRouteName(route.name);
                          _routeController.text = route.name;
                          if (route.sectorName != null &&
                              route.sectorName!.isNotEmpty) {
                            formNotifier
                                .setSectorOrLocation(route.sectorName!);
                            _sectorController.text = route.sectorName!;
                          }
                        } else {
                          formNotifier.setRouteName('');
                          _routeController.clear();
                        }
                      },
                    );
                  },
                  borderRadius: AppRadius.borderSm,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInput,
                      borderRadius: AppRadius.borderSm,
                      border: Border.all(
                        color: formState.selectedCrag != null
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.landscape_rounded,
                          size: 20,
                          color: formState.selectedCrag != null
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            formState.selectedCrag?.name ??
                                'Tap to select outdoor crag',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: formState.selectedCrag != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                              fontWeight: formState.selectedCrag != null
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Route in Crag Dropdown
                Text(
                  'ROUTE IN CRAG (OPTIONAL)',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                if (formState.selectedCrag == null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: AppRadius.borderSm,
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Select an outdoor crag above to choose a route',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildCragRouteDropdown(context, formState.selectedCrag!),
                const SizedBox(height: 18),

                // 4. Sector / Specific Location Field
                Text(
                  'SECTOR OR WALL AREA (OPTIONAL)',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sectorController,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: colorScheme.onSurface),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Damai Wall, Cave Entrance, Approach Trail',
                    prefixIcon: Icon(Icons.place_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 18),

                // 5. Severity Level Selector
                Text(
                  'SEVERITY LEVEL',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSeverityChip(context, 'low', colorScheme),
                    _buildSeverityChip(context, 'medium', colorScheme),
                    _buildSeverityChip(context, 'high', colorScheme),
                  ],
                ),
                const SizedBox(height: 18),

                // 6. Description Input
                Text(
                  'DESCRIPTION & PRECAUTIONS *',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('hazard_description_field'),
                  controller: _descriptionController,
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a brief description of the hazard.';
                    }
                    return null;
                  },
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: colorScheme.onSurface),
                  decoration: const InputDecoration(
                    hintText:
                        'Describe what you saw, specific location on pitch/wall, and guidance for climbers...',
                  ),
                ),
                const SizedBox(height: 18),

                // 7. Photo Attachment Placeholder
                Text(
                  'PHOTO ATTACHMENT (OPTIONAL)',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Photo attachment simulated'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: AppRadius.borderSm,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: AppRadius.borderSm,
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 28,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add Photo of Hazard',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                if (formState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      formState.errorMessage!,
                      style: TextStyle(color: colorScheme.error, fontSize: 13),
                    ),
                  ),

                // 8. Submit Hazard Report Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: formState.isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: formState.isSubmitting
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation(colorScheme.onPrimary),
                            ),
                          )
                        : Text(
                            'SUBMIT HAZARD REPORT',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCragRouteDropdown(BuildContext context, Crag crag) {
    final colorScheme = Theme.of(context).colorScheme;
    final formState = ref.watch(hazardReportFormProvider);
    final formNotifier = ref.read(hazardReportFormProvider.notifier);
    final routes = ref.watch(cragRoutesProvider(crag.id)).value ?? [];

    final isKnownRoute = routes.any((r) => r.name == formState.routeName);
    final isCustom = formState.routeName.isNotEmpty && !isKnownRoute;

    final selectedDropdownValue = formState.routeName.isEmpty
        ? null
        : (isKnownRoute ? formState.routeName : '__custom__');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: AppRadius.borderSm,
        border: Border.all(
          color: formState.routeName.isNotEmpty
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          key: const Key('report_form_route_dropdown'),
          value: selectedDropdownValue,
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          hint: Text(
            'Entire Crag / General Area (No specific route)',
            style: AppTextStyles.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'Entire Crag / General Area',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ...routes.map((route) {
              return DropdownMenuItem<String?>(
                value: route.name,
                child: Text(
                  '${route.name} (${route.grade})',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
            DropdownMenuItem<String?>(
              value: '__custom__',
              child: Text(
                isCustom
                    ? 'Custom: ${formState.routeName} (Tap to change)'
                    : '+ Enter custom route name...',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          onChanged: (val) async {
            if (val == null) {
              formNotifier.setRouteName('');
              _routeController.clear();
            } else if (val == '__custom__') {
              final custom = await _showCustomRouteDialog(context);
              if (custom != null && custom.isNotEmpty) {
                formNotifier.setRouteName(custom);
                _routeController.text = custom;
              } else if (formState.routeName.isEmpty) {
                // If cancelled and was previously empty, remain null
                formNotifier.setRouteName('');
                _routeController.clear();
              }
            } else {
              formNotifier.setRouteName(val);
              _routeController.text = val;
              final matched = routes.firstWhere((r) => r.name == val);
              if (matched.sectorName != null &&
                  matched.sectorName!.isNotEmpty) {
                formNotifier.setSectorOrLocation(matched.sectorName!);
                _sectorController.text = matched.sectorName!;
              }
            }
          },
        ),
      ),
    );
  }

  Future<String?> _showCustomRouteDialog(BuildContext context) async {
    final controller = TextEditingController(text: _routeController.text);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Custom Route Name'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter route name (e.g. Wall of Sound)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('SET ROUTE'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeverityChip(
    BuildContext context,
    String key,
    ColorScheme colorScheme,
  ) {
    final selectedSeverity = ref.watch(hazardReportFormProvider).severity;
    final isSelected = selectedSeverity == key;

    return ChoiceChip(
      label: Text(key.toUpperCase()),
      selected: isSelected,
      selectedColor: colorScheme.primary,
      backgroundColor: AppColors.surfaceInput,
      labelStyle: AppTextStyles.bodySmall.copyWith(
        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
        width: 1.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(hazardReportFormProvider.notifier).setSeverity(key);
        }
      },
    );
  }
}