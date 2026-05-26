import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static late String _backendUrl;
  static late String _geoapifyApiKey;

  static Future<void> init() async {
    await dotenv.load();
    _backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
    _geoapifyApiKey =
        dotenv.env['GEOAPIFY_API_KEY']?.trim() ??
        dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ??
        '';
  }

  static String get backendUrl => _backendUrl;

  /// Geoapify Maps API key — https://www.geoapify.com/get-started-with-maps-api/
  static String get geoapifyApiKey => _geoapifyApiKey;

  static bool get hasGeoapifyApiKey => _geoapifyApiKey.isNotEmpty;
}
