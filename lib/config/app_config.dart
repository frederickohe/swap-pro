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
    final envBackendUrl = dotenv.env['BACKEND_URL'];

    if (defineBackendUrl.isNotEmpty) {
      _backendUrl = _sanitizeUrl(defineBackendUrl);
    } else if (envBackendUrl != null && envBackendUrl.trim().isNotEmpty) {
      _backendUrl = _sanitizeUrl(envBackendUrl);
    } else {
      // Never fall back to localhost — that is unreachable on a real phone.
      _backendUrl = productionBackendUrl;
    }
    debugPrint('AppConfig.backendUrl=$_backendUrl');

    const defineGeoKey = String.fromEnvironment('GEOAPIFY_API_KEY');
    _geoapifyApiKey = defineGeoKey.isNotEmpty
        ? defineGeoKey
        : (dotenv.env['GEOAPIFY_API_KEY']?.replaceAll('\r', '').trim() ??
            dotenv.env['GOOGLE_MAPS_API_KEY']?.replaceAll('\r', '').trim() ??
            '');
  }

  static String _sanitizeUrl(String raw) {
    var url = raw.replaceAll('\r', '').trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static String get backendUrl => _backendUrl;

  /// Geoapify Maps API key — https://www.geoapify.com/get-started-with-maps-api/
  static String get geoapifyApiKey => _geoapifyApiKey;

  static bool get hasGeoapifyApiKey => _geoapifyApiKey.isNotEmpty;
}
