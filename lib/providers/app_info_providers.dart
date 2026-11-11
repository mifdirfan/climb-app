import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Installed app version, e.g. `1.0.0 (1)`.
///
/// - @source: Platform package metadata (pubspec `version:` at build time).
/// - @sink: Settings footer.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  final version = info.buildNumber.isEmpty
      ? info.version
      : '${info.version} (${info.buildNumber})';
  debugPrint('--> [SETTINGS:STATE] Resolved app version $version');
  return version;
});

/// Opens [uri] outside the app (mail client, browser, Discord).
/// Returns `false` if no app can handle it.
typedef ExternalLinkLauncher = Future<bool> Function(Uri uri);

/// Overridable seam over `url_launcher` so widget tests can assert the URI
/// without a platform channel.
final externalLinkLauncherProvider = Provider<ExternalLinkLauncher>((ref) {
  return (uri) async {
    debugPrint('--> [SETTINGS:STATE] Launching external link ${uri.scheme}:');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('--> [SETTINGS:STATE] 🛑 Could not launch link: $e');
      return false;
    }
  };
});
