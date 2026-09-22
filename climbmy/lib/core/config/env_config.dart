import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized access to environment variables loaded from `.env`.
class EnvConfig {
  EnvConfig._();

  /// Google Maps API Key retrieved from `.env`.
  static String get googleMapsApiKey =>
      dotenv.maybeGet('GOOGLE_MAPS_API_KEY') ?? '';

  /// Returns true if a custom key has been configured by the user.
  static bool get hasValidGoogleMapsKey {
    final key = googleMapsApiKey.trim();
    return key.isNotEmpty && key != 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
  }
}
