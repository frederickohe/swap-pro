import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:swappro/config/app_config.dart';
import 'package:swappro/services/api_http_client.dart';

/// Lightweight reachability check against the Swap Pro API.
class BackendConnectivity {
  static const Duration _timeout = Duration(seconds: 8);

  static Future<bool> isReachable() async {
    final uri = Uri.parse('${AppConfig.backendUrl}/api/v1/');
    try {
      final response = await apiHttpClient.get(uri).timeout(_timeout);
      return response.statusCode >= 200 && response.statusCode < 500;
    } on SocketException catch (e) {
      debugPrint('BackendConnectivity SocketException: $e url=$uri');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('BackendConnectivity timeout: $e url=$uri');
      return false;
    } on http.ClientException catch (e) {
      debugPrint('BackendConnectivity ClientException: $e url=$uri');
      return false;
    } on HandshakeException catch (e) {
      debugPrint('BackendConnectivity HandshakeException: $e url=$uri');
      return false;
    } on TlsException catch (e) {
      debugPrint('BackendConnectivity TlsException: $e url=$uri');
      return false;
    } catch (e) {
      debugPrint('BackendConnectivity error: $e url=$uri');
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
