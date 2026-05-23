import 'package:jwt_decoder/jwt_decoder.dart';

class TokenModel {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn; // in seconds

  TokenModel({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
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

  /// Get the expiration time as DateTime
  DateTime get expirationDateTime {
    return DateTime.now().add(Duration(seconds: expiresIn));
  }

  /// Check if token is expired
  bool get isExpired {
    try {
      return JwtDecoder.isExpired(accessToken);
    } catch (_) {
      return true;
    }
  }

  /// Check if token should be refreshed (refresh if expiry is within 5 minutes)
  bool get shouldRefresh {
    try {
      final expirationTime = JwtDecoder.getExpirationDate(accessToken);
      final now = DateTime.now();
      final fiveMinutesFromNow = now.add(const Duration(minutes: 5));
      return expirationTime.isBefore(fiveMinutesFromNow);
    } catch (_) {
      return true;
    }
  }

  /// Decode JWT and get payload
  Map<String, dynamic> get accessTokenPayload {
    try {
      return JwtDecoder.decode(accessToken);
    } catch (_) {
      return {};
    }
  }

  /// Get user email from token
  String? get userEmail {
    try {
      final payload = accessTokenPayload;
      return payload['sub']; // 'sub' is the subject (email in your case)
    } catch (_) {
      return null;
    }
  }
}
