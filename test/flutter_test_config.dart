import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Global test bootstrap, picked up automatically by `flutter test`.
///
/// `AppTextStyles` resolves Space Grotesk / JetBrains Mono through
/// `google_fonts`, which would otherwise try to download fonts over HTTP.
/// Tests must stay hermetic, so runtime fetching is disabled; text falls back
/// to the default test font (missing-font errors are swallowed by the package).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
