import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/app_links.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_info_providers.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/settings/settings_tile.dart';

/// App settings: community, support, legal, and account actions, with the
/// app version + contact address in the footer.
///
/// To add a setting, drop a [SettingsTile] into the relevant [SettingsGroup]
/// (or add a new group) in [build].
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  void _snack(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  Future<void> _launch(Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(externalLinkLauncherProvider)(uri);
    if (!ok) _snack(messenger, 'No app available to open this link.');
  }

  void _openDiscord() {
    debugPrint('--> [SETTINGS:UI] Discord tapped');
    final invite = AppLinks.discordInvite;
    if (invite == null) {
      _snack(ScaffoldMessenger.of(context), 'Our Discord is coming soon!');
      return;
    }
    _launch(Uri.parse(invite));
  }

  void _contact() {
    debugPrint('--> [SETTINGS:UI] Contact Us tapped');
    _launch(AppLinks.mailto(subject: 'ClimbMY enquiry'));
  }

  void _report() {
    debugPrint('--> [SETTINGS:UI] Report a Problem tapped');
    final version = ref.read(appVersionProvider).value ?? 'unknown';
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name;
    _launch(AppLinks.mailto(
      subject: 'ClimbMY problem report',
      body: 'Describe the problem:\n\n\n'
          'Steps to reproduce:\n\n\n'
          '---\nApp version: $version\nPlatform: $platform',
    ));
  }

  Future<void> _signOut() async {
    debugPrint('--> [SETTINGS:UI] Sign Out tapped');
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    setState(() => _busy = false);
    _snack(messenger, 'Logged out successfully.');
    context.pop();
  }

  Future<void> _deleteAccount() async {
    debugPrint('--> [SETTINGS:UI] Delete Account tapped');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) {
      debugPrint('--> [SETTINGS:UI] Delete Account cancelled');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    final ok = await ref.read(authControllerProvider.notifier).deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);

    if (ok) {
      _snack(messenger, 'Your account has been deleted.');
      context.go(AppRoutes.crags);
    } else {
      final error = ref.read(authControllerProvider).error;
      _snack(messenger, error is String ? error : 'Could not delete your account.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final email = ref.watch(currentUserProvider)?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: context.textStyles.titleLarge),
        centerTitle: false,
      ),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _busy,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_busy) ...[
                LinearProgressIndicator(
                  minHeight: 2,
                  color: palette.accent,
                  backgroundColor: palette.borderSubtle,
                ),
                const SizedBox(height: 12),
              ],

              SettingsGroup(
                title: 'Community',
                children: [
                  SettingsTile(
                    key: const Key('settings_discord'),
                    icon: Icons.forum_outlined,
                    title: 'Join our Discord',
                    subtitle: 'Chat beta, find partners, share conditions',
                    badge: AppLinks.discordInvite == null ? 'SOON' : null,
                    trailing: SettingsTileTrailing.external,
                    onTap: _openDiscord,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SettingsGroup(
                title: 'Support',
                children: [
                  SettingsTile(
                    key: const Key('settings_contact'),
                    icon: Icons.mail_outline_rounded,
                    title: 'Contact Us',
                    subtitle: 'Questions, feedback or partnerships',
                    trailing: SettingsTileTrailing.external,
                    onTap: _contact,
                  ),
                  SettingsTile(
                    key: const Key('settings_report'),
                    icon: Icons.bug_report_outlined,
                    title: 'Report a Problem',
                    subtitle: 'Something broken or wrong in the app',
                    trailing: SettingsTileTrailing.external,
                    onTap: _report,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SettingsGroup(
                title: 'Legal',
                children: [
                  SettingsTile(
                    key: const Key('settings_privacy'),
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => context.push(AppRoutes.privacyPolicy),
                  ),
                  SettingsTile(
                    key: const Key('settings_terms'),
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    onTap: () => context.push(AppRoutes.terms),
                  ),
                ],
              ),

              if (isAuthenticated) ...[
                const SizedBox(height: 20),
                SettingsGroup(
                  title: 'Account',
                  children: [
                    SettingsTile(
                      key: const Key('settings_sign_out'),
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      subtitle: email != null ? 'Signed in as $email' : null,
                      trailing: SettingsTileTrailing.none,
                      onTap: _signOut,
                    ),
                    SettingsTile(
                      key: const Key('settings_delete_account'),
                      icon: Icons.delete_forever_outlined,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account and data',
                      tone: SettingsTileTone.destructive,
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),
              _Footer(onContact: _contact),
            ],
          ),
        ),
      ),
    );
  }
}

/// App version + support address, centred under the last group.
class _Footer extends ConsumerWidget {
  const _Footer({required this.onContact});
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final text = context.textStyles;
    final version = ref.watch(appVersionProvider).when(
          data: (v) => 'v$v',
          loading: () => '…',
          error: (_, _) => '',
        );

    return Column(
      children: [
        Text(
          'ClimbMY $version'.trim(),
          key: const Key('settings_version'),
          style: text.caption.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: 4),
        InkWell(
          key: const Key('settings_footer_contact'),
          onTap: onContact,
          borderRadius: AppRadius.borderXs,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(
              AppLinks.supportEmail,
              style: text.caption.copyWith(
                color: palette.accent,
                decoration: TextDecoration.underline,
                decorationColor: palette.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Explicit, irreversible-action confirmation. Pops `true` to proceed.
class _DeleteAccountDialog extends StatelessWidget {
  const _DeleteAccountDialog();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = context.textStyles;

    return AlertDialog(
      backgroundColor: palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderLg),
      title: Text('Delete account?', style: text.titleMedium),
      content: Text(
        'This permanently deletes your profile, tick history, indoor sessions '
        'and saved crags. Hazard reports you submitted stay up but are no longer '
        'linked to you.\n\nThis cannot be undone.',
        style: text.bodySmall,
      ),
      actions: [
        TextButton(
          key: const Key('delete_account_cancel'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel', style: text.labelMedium),
        ),
        TextButton(
          key: const Key('delete_account_confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Delete', style: text.labelMedium.copyWith(color: palette.hazardText)),
        ),
      ],
    );
  }
}
