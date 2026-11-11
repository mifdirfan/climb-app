import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'legal_content.dart';

/// Read-only static page for bundled legal text (Privacy Policy, Terms).
///
/// Bundled rather than a web view so it works offline at the crag and
/// needs no hosting.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title, style: text.titleLarge),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Last updated ${document.lastUpdated}',
              style: text.caption.copyWith(color: palette.textMuted),
            ),
            const SizedBox(height: 16),
            for (final section in document.sections) ...[
              Text(section.heading, style: text.titleSmall),
              const SizedBox(height: 6),
              Text(section.body, style: text.bodyMedium),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
