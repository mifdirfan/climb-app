import 'package:climbmy/core/theme/app_theme.dart';
import 'package:climbmy/widgets/settings/settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(body: child),
  ));
}

void main() {
  group('SettingsTile', () {
    testWidgets('renders title, subtitle and default chevron; fires onTap', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        SettingsTile(
          icon: Icons.star,
          title: 'Title',
          subtitle: 'Sub',
          onTap: () => taps++,
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Sub'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.text('Title'));
      expect(taps, 1);
    });

    testWidgets('external trailing shows open-in-new instead of chevron', (tester) async {
      await _pump(
        tester,
        SettingsTile(
          icon: Icons.mail,
          title: 'Mail',
          trailing: SettingsTileTrailing.external,
          onTap: () {},
        ),
      );
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('destructive tone uses hazard colour and hides chevron', (tester) async {
      await _pump(
        tester,
        SettingsTile(
          icon: Icons.delete,
          title: 'Delete',
          tone: SettingsTileTone.destructive,
          onTap: () {},
        ),
      );
      final title = tester.widget<Text>(find.text('Delete'));
      expect(title.style!.color, AppPalette.dark.hazardText);
      final icon = tester.widget<Icon>(find.byIcon(Icons.delete));
      expect(icon.color, AppPalette.dark.hazardText);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('badge renders next to the title', (tester) async {
      await _pump(
        tester,
        SettingsTile(icon: Icons.forum, title: 'Discord', badge: 'SOON', onTap: () {}),
      );
      expect(find.text('SOON'), findsOneWidget);
    });

    testWidgets('null onTap renders dimmed', (tester) async {
      await _pump(tester, const SettingsTile(icon: Icons.block, title: 'Off'));
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: find.text('Off'), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, 0.5);
    });

    testWidgets('trailingWidget overrides trailing enum', (tester) async {
      await _pump(
        tester,
        SettingsTile(
          icon: Icons.tune,
          title: 'Custom',
          trailingWidget: const Text('ON'),
          onTap: () {},
        ),
      );
      expect(find.text('ON'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });
  });

  group('SettingsGroup', () {
    testWidgets('uppercases title and puts a divider between each pair of rows', (tester) async {
      await _pump(
        tester,
        SettingsGroup(
          title: 'Legal',
          children: [
            SettingsTile(icon: Icons.star, title: 'One', onTap: () {}),
            SettingsTile(icon: Icons.home, title: 'Two', onTap: () {}),
            SettingsTile(icon: Icons.info, title: 'Three', onTap: () {}),
          ],
        ),
      );
      expect(find.text('LEGAL'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('untitled single-row group has no header and no divider', (tester) async {
      await _pump(
        tester,
        SettingsGroup(children: [SettingsTile(icon: Icons.star, title: 'Solo', onTap: () {})]),
      );
      expect(find.byType(Divider), findsNothing);
      expect(find.text('Solo'), findsOneWidget);
    });
  });
}
