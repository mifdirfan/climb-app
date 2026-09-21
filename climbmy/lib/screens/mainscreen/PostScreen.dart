// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/home_providers.dart';
import '../../providers/post_form_providers.dart';
import '../../widgets/foam/foam.dart';
import '../../widgets/post_type_selector.dart';

/// Alias to support both PostScreen and PostPage naming.
typedef PostScreen = PostPage;

/// Screen for logging outdoor sends or indoor gym sessions.
class PostPage extends ConsumerStatefulWidget {
  final String? initialCragId;
  final VoidCallback? onBack;
  final ValueChanged<Map<String, dynamic>>? onPostSend;

  const PostPage({
    super.key,
    this.initialCragId,
    this.onBack,
    this.onPostSend,
  });

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  void _navigateAfterSubmit() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/crags');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postType = ref.watch(postTypeProvider);
    final isOutdoor = postType == ClimbPostType.outdoor;

    // Auto-select initialCragId if provided
    final cragsAsync = ref.watch(cragsProvider);
    cragsAsync.whenData((crags) {
      if (widget.initialCragId != null) {
        final match = crags.where((c) => c.id == widget.initialCragId);
        if (match.isNotEmpty) {
          final outdoorState = ref.read(outdoorPostFormProvider);
          if (outdoorState.selectedCrag == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(outdoorPostFormProvider.notifier).setSelectedCrag(match.first);
              }
            });
          }
        }
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isOutdoor ? 'LOG A SEND' : 'LOG GYM SESSION',
          style: AppTextStyles.displayLarge.copyWith(
            fontSize: 28,
            color: AppColors.primaryContainer,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Mode Selector: Outdoor vs Indoor
              PostTypeSelector(
                selectedType: postType,
                onTypeChanged: (type) {
                  ref.read(postTypeProvider.notifier).setType(type);
                },
              ),

              const SizedBox(height: 20),

              // Switchable Form based on PostType
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isOutdoor
                    ? OutdoorForm(
                        key: const ValueKey('outdoor_form'),
                        onSubmitted: _navigateAfterSubmit,
                        onPostSend: widget.onPostSend,
                      )
                    : IndoorForm(
                        key: const ValueKey('indoor_form'),
                        onSubmitted: _navigateAfterSubmit,
                        onPostSend: widget.onPostSend,
                      ),
              ),

              // Clearance for FloatingBottomNavBar
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
