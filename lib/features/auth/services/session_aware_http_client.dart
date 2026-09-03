import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:swappro/barrel.dart';
import 'package:swappro/services/api_http_client.dart';

/// HTTP Client wrapper with automatic token injection and refresh
/// This client automatically:
/// - Proactively refreshes tokens before they expire
/// - Injects Authorization headers with the current access token
/// - Handles 401 responses by attempting token refresh
/// - Retries the original request after successful token refresh
class SessionAwareHttpClient extends http.BaseClient {
  final TokenService tokenService;
  final String? baseUrl;
  final ConnectivityNotifier? connectivityNotifier;
  final http.Client _innerClient = apiHttpClient;

  /// Called when refresh fails and the user must sign in again.
  VoidCallback? onSessionExpired;

  Future<bool>? _ongoingRefresh;

  SessionAwareHttpClient({
    required this.tokenService,
    this.baseUrl,
    this.connectivityNotifier,
  });

  Future<void> _ensureFreshAccessToken() async {
    final token = await tokenService.getToken();
    if (token == null) return;
    if (token.isRefreshTokenExpired) return;

    final needsRefresh = token.isExpired || token.shouldRefresh;
    if (!needsRefresh) return;

    final refreshToken = token.refreshToken;
    if (refreshToken.isEmpty) return;

    await _refreshToken(refreshToken);
  }

  Future<void> _handleRefreshFailure(String refreshToken) async {
    try {
      final stored = await tokenService.getToken();
      final candidate = stored?.refreshToken ?? refreshToken;
      if (candidate.isNotEmpty && !JwtDecoder.isExpired(candidate)) {
        // Refresh token is still valid — keep the local session and retry later.
        return;
      }
    } catch (_) {}

    await tokenService.clearTokens();
    onSessionExpired?.call();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await _ensureFreshAccessToken();

    // Get current access token and add to headers
    final accessToken = await tokenService.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    http.StreamedResponse response;
    try {
      response = await _innerClient
          .send(request)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      connectivityNotifier?.reportUnreachable();
      rethrow;
    } catch (e) {
      if (BackendConnectivity.isNetworkFailure(e)) {
        connectivityNotifier?.reportUnreachable();
      }
      rethrow;
    }

    connectivityNotifier?.clear();

    // If we get a 401, attempt token refresh and retry
    if (response.statusCode == 401) {
      final refreshToken = await tokenService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
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
              rethrow;
            }
            if (response.statusCode != 401) {
              connectivityNotifier?.clear();
              return response;
            }
          }
        }
      }
      final refreshTokenForFailure = refreshToken ?? '';
      if (refreshTokenForFailure.isNotEmpty) {
        await _handleRefreshFailure(refreshTokenForFailure);
      } else {
        await tokenService.clearTokens();
        onSessionExpired?.call();
      }
    }

    return response;
  }

  /// Attempt to refresh the access token using the refresh token
  Future<bool> _refreshToken(String refreshToken) {
    final inFlight = _ongoingRefresh;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _performRefresh(refreshToken);
    _ongoingRefresh = future;
    return future.whenComplete(() {
      if (identical(_ongoingRefresh, future)) {
        _ongoingRefresh = null;
      }
    });
  }

  Future<bool> _performRefresh(String refreshToken) async {
    try {
      if (JwtDecoder.isExpired(refreshToken)) {
        return false;
      }

      final url = baseUrl != null
          ? Uri.parse('$baseUrl/api/v1/auth/refresh')
          : Uri.parse('${AppConfig.backendUrl}/api/v1/auth/refresh');

      final response = await apiHttpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await tokenService.updateToken(TokenModel.fromJson(data));
        return true;
      }
      return false;
    } catch (e) {
      if (BackendConnectivity.isNetworkFailure(e)) {
        return false;
      }
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
