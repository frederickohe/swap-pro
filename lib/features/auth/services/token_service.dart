import 'package:swappro/barrel.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  final FlutterSecureStorage _secureStorage;

  TokenService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Save token to secure storage
  Future<void> saveToken(TokenModel token) async {
    try {
      await _secureStorage.write(
        key: _tokenKey,
        value: json.encode(token.toJson()),
      );
      await _secureStorage.write(
        key: _tokenExpiryKey,
        value: token.expirationDateTime.toIso8601String(),
      );
    } catch (e) {
      throw Exception('Failed to save token: $e');
    }
  }

  /// Retrieve token from secure storage
  Future<TokenModel?> getToken() async {
    try {
      final tokenJson = await _secureStorage.read(key: _tokenKey);
      if (tokenJson == null) return null;

      final decoded = json.decode(tokenJson) as Map<String, dynamic>;
      return TokenModel.fromJson(decoded);
    } catch (e) {
      throw Exception('Failed to retrieve token: $e');
    }
  }

  /// Get access token string
  Future<String?> getAccessToken() async {
    try {
      final token = await getToken();
      return token?.accessToken;
    } catch (e) {
      return null;
    }
  }

  /// Get refresh token string
  Future<String?> getRefreshToken() async {
    try {
      final token = await getToken();
      return token?.refreshToken;
    } catch (e) {
      return null;
    }
  }

  /// Update tokens after refresh
  Future<void> updateToken(TokenModel newToken) async {
    try {
      await saveToken(newToken);
    } catch (e) {
      throw Exception('Failed to update token: $e');
    }
  }

  /// Check if token is still valid
  Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      return !token.isExpired;
    } catch (e) {
      return false;
    }
  }

  /// Check if token should be refreshed (within 5 minutes of expiry)
  Future<bool> shouldRefreshToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      return token.shouldRefresh;
    } catch (e) {
      return false;
    }
  }

  /// Get token expiration time
  Future<DateTime?> getTokenExpiration() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      return token.expirationDateTime;
    } catch (e) {
      return null;
    }
  }

  /// Get user email from token
  Future<String?> getUserEmail() async {
    try {
      final token = await getToken();
      return token?.userEmail;
    } catch (e) {
      return null;
    }
  }

  /// Clear all tokens (logout)
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _tokenExpiryKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    } catch (e) {
      throw Exception('Failed to clear tokens: $e');
    }
  }

  /// Check if user has valid session
  Future<bool> hasValidSession() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      return !token.isExpired;
    } catch (e) {
      return false;
    }
  }
}
