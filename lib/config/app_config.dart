import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  /// Production API — used when `.env` is missing (e.g. Play Store CI builds).
  static const String productionBackendUrl = 'https://api.swappro.store';

  static late String _backendUrl;
  static late String _geoapifyApiKey;

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('AppConfig: .env not loaded ($e); using defaults');
    }

    const defineBackendUrl = String.fromEnvironment('BACKEND_URL');
    final envBackendUrl = dotenv.env['BACKEND_URL']?.trim();

    if (defineBackendUrl.isNotEmpty) {
      _backendUrl = defineBackendUrl;
    } else if (envBackendUrl != null && envBackendUrl.isNotEmpty) {
      _backendUrl = envBackendUrl;
    } else {
      _backendUrl = kReleaseMode
          ? productionBackendUrl
          : 'http://localhost:8000';
    }

    const defineGeoKey = String.fromEnvironment('GEOAPIFY_API_KEY');
    _geoapifyApiKey = defineGeoKey.isNotEmpty
        ? defineGeoKey
        : (dotenv.env['GEOAPIFY_API_KEY']?.trim() ??
            dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ??
            '');
  }

  static String get backendUrl => _backendUrl;

  /// Geoapify Maps API key — https://www.geoapify.com/get-started-with-maps-api/
  static String get geoapifyApiKey => _geoapifyApiKey;

  static bool get hasGeoapifyApiKey => _geoapifyApiKey.isNotEmpty;
}
