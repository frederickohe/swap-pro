import 'dart:io' show Platform;

import 'package:swappro/config/app_config.dart';

/// Rewrites integration URLs so WebViews on emulators/devices can reach dev servers.
///
/// When the API returns `http://localhost:4007`, phones cannot reach the host PC.
/// If [AppConfig.backendUrl] uses a LAN IP (e.g. `http://192.168.1.5:8000`), that
/// host replaces `localhost`. On Android emulators, falls back to `10.0.2.2`.
String resolveEmbeddedPlatformUrl(String url) {
  if (url.isEmpty) return url;
  final uri = Uri.tryParse(url);
  if (uri == null) return url;

  if (uri.host != 'localhost' && uri.host != '127.0.0.1') {
    return url;
  }

  final backend = Uri.tryParse(AppConfig.backendUrl);
  final backendHost = backend?.host ?? '';
  if (backendHost.isNotEmpty &&
      backendHost != 'localhost' &&
      backendHost != '127.0.0.1') {
    return uri.replace(host: backendHost).toString();
  }

  if (Platform.isAndroid) {
    return uri.replace(host: '10.0.2.2').toString();
  }

  return url;
}
