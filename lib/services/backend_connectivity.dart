import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:swappro/config/app_config.dart';

/// Lightweight reachability check against the Swap Pro API.
class BackendConnectivity {
  static const Duration _timeout = Duration(seconds: 8);

  static Future<bool> isReachable() async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.backendUrl}/api/v1/'))
          .timeout(_timeout);
      return response.statusCode >= 200 && response.statusCode < 500;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } on http.ClientException {
      return false;
    } on HandshakeException {
      return false;
    } on TlsException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static bool isNetworkFailure(Object error) {
    return error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is TlsException;
  }
}
