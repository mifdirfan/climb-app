import 'dart:io';

import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/widgets/auth_required_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// WCAG relative-contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('UI code reads design tokens from the theme', () {
    final uiFiles = [
      ...Directory('lib/screens').listSync(recursive: true),
      ...Directory('lib/widgets').listSync(recursive: true),
    ].whereType<File>().where((f) => f.path.endsWith('.dart')).toList();

    /// pattern -> why it is banned in lib/screens + lib/widgets.
    final banned = <RegExp, String>{
      RegExp(r'\bAppColors\.'): 'use context.palette.* (brightness-aware)',
      RegExp(r'\bAppTextStyles\.'): 'use context.textStyles.* (brightness-aware)',
      RegExp(r'\bColors\.(?!transparent\b)\w+'): 'use a context.palette token',
      RegExp(r'(?<![.\w])TextStyle\('): 'use a context.textStyles role + copyWith',
      RegExp(r'Radius\.circular\(\d'): 'use an AppRadius token',
    };
    // Gym grading tags are data-driven hex colours (CLAUDE.md §3) — allowed.
    final allowedHex = RegExp(r'Color\(0xFF000000 \| intVal\)');

    test('no banned literals in ${uiFiles.length} UI files', () {
      final violations = <String>[];
      for (final f in uiFiles) {
        final lines = f.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          banned.forEach((re, why) {
            if (re.hasMatch(line)) violations.add('${f.path}:${i + 1}  $why\n    ${line.trim()}');
          });
          if (line.contains('Color(0x') && !allowedHex.hasMatch(line)) {
            violations.add('${f.path}:${i + 1}  hex literal; add an AppPalette token\n    ${line.trim()}');
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });

  group('AppPalette', () {
    test('dark palette is identical to the original dark-only AppColors', () {
      const p = AppPalette.dark;
      expect(p.background, AppColors.background);
      expect(p.surface, AppColors.surface);
      expect(p.textPrimary, AppColors.textPrimary);
      expect(p.textMuted, AppColors.textMuted);
      expect(p.border, AppColors.border);
      expect(p.primary, AppColors.primary);
      expect(p.accent, AppColors.primary, reason: 'accent stays lime in dark mode');
      expect(p.hazardText, AppColors.hazardText);
    });

    test('light palette text is readable (WCAG AA 4.5:1) on light surfaces', () {
      const p = AppPalette.light;
      for (final bg in [p.background, p.surface, p.surfaceElevated]) {
        expect(contrast(p.textPrimary, bg), greaterThanOrEqualTo(4.5));
        expect(contrast(p.textSecondary, bg), greaterThanOrEqualTo(4.5));
      }
    });

    test('light accent is legible where lime-on-white would not be', () {
      const p = AppPalette.light;
      expect(contrast(AppColors.primary, p.surface), lessThan(3),
          reason: 'sanity: raw lime on white fails, which is why accent exists');
      expect(contrast(p.accent, p.surface), greaterThanOrEqualTo(4.5));
    });

    test('lime fill keeps readable onPrimary text in both themes', () {
      for (final p in [AppPalette.dark, AppPalette.light]) {
        expect(contrast(p.onPrimary, p.primary), greaterThanOrEqualTo(4.5));
      }
    });

    test('lerp between palettes interpolates (theme animation)', () {
      final mid = AppPalette.dark.lerp(AppPalette.light, 0.5);
      expect(mid.surface, isNot(AppPalette.dark.surface));
      expect(mid.surface, isNot(AppPalette.light.surface));
    });
  });

  group('Widgets resolve tokens from the active theme', () {
    Future<Text> pumpTitle(WidgetTester tester, ThemeData theme) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, _) => const AuthRequiredView(title: 'Token Title')),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(theme: theme, routerConfig: router));
      await tester.pumpAndSettle();
      return tester.widget<Text>(find.text('Token Title'));
    }

    testWidgets('light theme renders dark text', (tester) async {
      final text = await pumpTitle(tester, AppTheme.lightTheme);
      expect(text.style!.color, AppPalette.light.textPrimary);
    });

    testWidgets('dark theme renders light text', (tester) async {
      final text = await pumpTitle(tester, AppTheme.darkTheme);
      expect(text.style!.color, AppPalette.dark.textPrimary);
    });

    testWidgets('falls back to dark palette when no AppTheme is installed', (tester) async {
      final text = await pumpTitle(tester, ThemeData());
      expect(text.style!.color, AppPalette.dark.textPrimary);
    });
  });
}
