import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swappro/config/app_config.dart';
import 'package:swappro/services/api_http_client.dart';

/// A place suggestion from Geoapify autocomplete.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  final String label;
  final double latitude;
  final double longitude;
}

/// Geoapify reverse geocoding + autocomplete — works globally without a fixed location list.
class GeocodingService {
  GeocodingService({http.Client? client}) : _client = client ?? apiHttpClient;

  final http.Client _client;

  static const _reverseUrl = 'https://api.geoapify.com/v1/geocode/reverse';
  static const _autocompleteUrl =
      'https://api.geoapify.com/v1/geocode/autocomplete';

  String? get _apiKey {
    final key = AppConfig.geoapifyApiKey.trim();
    return key.isEmpty ? null : key;
  }

  /// Convert coordinates to a suburb/city-level label (never street-level).
  Future<String?> reverseGeocodeArea({
    required double latitude,
    required double longitude,
  }) async {
    final apiKey = _apiKey;
    if (apiKey == null) return null;

    final uri = Uri.parse(_reverseUrl).replace(
      queryParameters: {
        'lat': '$latitude',
        'lon': '$longitude',
        'apiKey': apiKey,
        'lang': 'en',
      },
    );

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body);
      if (payload is! Map) return null;
      final features = payload['features'];
      if (features is! List || features.isEmpty) return null;
      final first = features.first;
      if (first is! Map) return null;
      final props = first['properties'];
      if (props is! Map) return null;
      return _displayAreaFromProperties(Map<String, dynamic>.from(props));
    } catch (_) {
      return null;
    }
  }

  /// Search places by name — used on the filter screen instead of a static list.
  Future<List<PlaceSuggestion>> autocomplete(String query) async {
    final apiKey = _apiKey;
    final trimmed = query.trim();
    if (apiKey == null || trimmed.length < 2) return const [];

    final uri = Uri.parse(_autocompleteUrl).replace(
      queryParameters: {
        'text': trimmed,
        'apiKey': apiKey,
        'lang': 'en',
        'limit': '8',
      },
    );

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return const [];
      final payload = jsonDecode(response.body);
      if (payload is! Map) return const [];
      final features = payload['features'];
      if (features is! List) return const [];

      final results = <PlaceSuggestion>[];
      for (final feature in features) {
        if (feature is! Map) continue;
        final props = feature['properties'];
        if (props is! Map) continue;
        final map = Map<String, dynamic>.from(props);
        final label = _suggestionLabel(map);
        if (label == null || label.isEmpty) continue;

        final lat = map['lat'];
        final lon = map['lon'];
        if (lat is! num || lon is! num) continue;

        results.add(
          PlaceSuggestion(
            label: label,
            latitude: lat.toDouble(),
            longitude: lon.toDouble(),
          ),
        );
      }
      return results;
    } catch (_) {
      return const [];
    }
  }

  static String? _displayAreaFromProperties(Map<String, dynamic> props) {
    final parts = <String>[];
    for (final key in ['suburb', 'district', 'neighbourhood', 'city']) {
      final val = (props[key] ?? '').toString().trim();
      if (val.isNotEmpty && !parts.contains(val)) {
        parts.add(val);
      }
      if (parts.length >= 2) break;
    }

    if (parts.isEmpty) {
      for (final key in ['city', 'county', 'state', 'country']) {
        final val = (props[key] ?? '').toString().trim();
        if (val.isNotEmpty) {
          parts.add(val);
          break;
        }
      }
    }

    return parts.isEmpty ? null : parts.join(', ');
  }

  static String? _suggestionLabel(Map<String, dynamic> props) {
    final formatted = (props['formatted'] ?? '').toString().trim();
    if (formatted.isNotEmpty) return formatted;
    return _displayAreaFromProperties(props);
  }
}
