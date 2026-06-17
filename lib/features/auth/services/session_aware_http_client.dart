import 'package:http/http.dart' as http;
import 'package:swappro/barrel.dart';

/// HTTP Client wrapper with automatic token injection and refresh
/// This client automatically:
/// - Injects Authorization headers with the current access token
/// - Handles 401 responses by attempting token refresh
/// - Retries the original request after successful token refresh
class SessionAwareHttpClient extends http.BaseClient {
  final TokenService tokenService;
  final String? baseUrl;
  final ConnectivityNotifier? connectivityNotifier;
  final http.Client _innerClient = http.Client();

  SessionAwareHttpClient({
    required this.tokenService,
    this.baseUrl,
    this.connectivityNotifier,
  });

  void _reportUnreachableIfNeeded(Object error) {
    // Network blips during normal API calls should not hijack navigation.
    // Session/bootstrap flows emit [ServerUnreachable] via [AuthBloc] instead.
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Get current access token and add to headers
    final accessToken = await tokenService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    http.StreamedResponse response;
    try {
      response = await _innerClient.send(request);
    } catch (e) {
      _reportUnreachableIfNeeded(e);
      rethrow;
    }

    // If we get a 401, attempt token refresh and retry
    if (response.statusCode == 401) {
      final refreshToken = await tokenService.getRefreshToken();
      if (refreshToken != null) {
        if (await _refreshToken(refreshToken)) {
          // Token was refreshed successfully, retry the original request
          final newAccessToken = await tokenService.getAccessToken();
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            request.headers['Authorization'] = 'Bearer $newAccessToken';
            // Clone the request to resend it
            final clonedRequest = _cloneRequest(request);
            try {
              response = await _innerClient.send(clonedRequest);
            } catch (e) {
              _reportUnreachableIfNeeded(e);
              rethrow;
            }
          }
        }
      }
    }

    return response;
  }

  /// Attempt to refresh the access token using the refresh token
  Future<bool> _refreshToken(String refreshToken) async {
    try {
      final url = baseUrl != null
          ? Uri.parse('$baseUrl/api/v1/auth/refresh')
          : Uri.parse('${AppConfig.backendUrl}/api/v1/auth/refresh');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Update the token using TokenService
        await tokenService.updateToken(TokenModel.fromJson(data));
        return true;
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
      return false;
    }
  }

  /// Clone a request to resend it
  http.BaseRequest _cloneRequest(http.BaseRequest request) {
    http.BaseRequest clonedRequest;

    if (request is http.Request) {
      clonedRequest = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      clonedRequest = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw Exception('Cannot clone StreamedRequest');
    } else {
      throw Exception('Cannot clone ${request.runtimeType}');
    }

    clonedRequest
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return clonedRequest;
  }
}

/// Internal TokenModel for HTTP client use
class _TokenModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  _TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory _TokenModel.fromJson(Map<String, dynamic> json) {
    return _TokenModel(
      accessToken: json['access_token'] ?? '',
      refreshToken: json['refresh_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      expiresIn: json['expires_in'] ?? 1800,
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'token_type': tokenType,
    'expires_in': expiresIn,
  };
}
