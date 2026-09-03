import 'dart:async';

import 'package:swappro/services/geocoding_service.dart';

final _locationCache = <String, String>{};

String _listingLocationCacheKey(Map<String, dynamic> listing) {
  final id = listing['id']?.toString().trim();
  if (id != null && id.isNotEmpty) return 'id:$id';
  final lat = listing['location_lat'];
  final lng = listing['location_lng'];
  if (lat is num && lng is num) {
    return 'coord:${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
  }
  return '';
}

/// Privacy-safe location label for listing cards and detail views.
String listingDisplayLocation(Map<String, dynamic> listing) {
  final area = (listing['location_area'] ?? '').toString().trim();
  if (area.isNotEmpty) return area;

  final key = _listingLocationCacheKey(listing);
  if (key.isNotEmpty) {
    final cached = _locationCache[key];
    if (cached != null && cached.isNotEmpty) return cached;
  }

  return 'Location unavailable';
}

/// Fills the in-memory cache for listings missing [location_area] but with coordinates.
Future<void> prefetchListingLocations(
  Iterable<Map<String, dynamic>> listings, {
  GeocodingService? geocoding,
}) async {
  final service = geocoding ?? GeocodingService();
  final pending = <Future<void>>[];

  for (final listing in listings) {
    final area = (listing['location_area'] ?? '').toString().trim();
    if (area.isNotEmpty) continue;

    final key = _listingLocationCacheKey(listing);
    if (key.isEmpty || _locationCache.containsKey(key)) continue;

    final lat = listing['location_lat'];
    final lng = listing['location_lng'];
    if (lat is! num || lng is! num) continue;

    pending.add(() async {
      final resolved = await service.reverseGeocodeArea(
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
      );
      final trimmed = resolved?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        _locationCache[key] = trimmed;
      }
    }());
  }

  if (pending.isNotEmpty) {
    try {
      await Future.wait(pending).timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
