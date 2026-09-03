import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Shared HTTP client for API calls.
///
/// Sets a connect timeout so a bad DNS/TLS handshake cannot freeze splash
/// or HomeEntry the way the default `http.Client` can on some Android devices.
http.Client createApiHttpClient() {
  final io = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12)
    ..idleTimeout = const Duration(seconds: 15)
    ..userAgent = 'SwapPro/1.0.0 (Dart)';
  return IOClient(io);
}

final http.Client apiHttpClient = createApiHttpClient();
