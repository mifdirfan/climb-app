/// External contact points and links surfaced in Settings.
///
/// Kept in one place so support addresses / community links can change
/// without touching UI code.
class AppLinks {
  AppLinks._();

  /// Support inbox for "Contact Us" and "Report a Problem".
  // TODO(settings): replace with the real support address before release.
  static const String supportEmail = 'support@climbmy.app';

  /// Discord invite. `null` until the server is ready; the Settings tile shows
  /// a "SOON" badge while this is unset.
  static const String? discordInvite = null;

  /// Builds a `mailto:` URI.
  ///
  /// Uses [Uri.encodeComponent] rather than `Uri(queryParameters:)`, which
  /// form-encodes spaces as `+` — most mail apps show those literally.
  static Uri mailto({required String subject, String? body}) {
    final query = [
      'subject=${Uri.encodeComponent(subject)}',
      if (body != null) 'body=${Uri.encodeComponent(body)}',
    ].join('&');
    return Uri.parse('mailto:$supportEmail?$query');
  }
}
