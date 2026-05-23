/// Session payload from swappro for embedded Postiz / Chatwoot sign-in in a WebView.
class PlatformEmbedSession {
  final String authorizationUrl;
  final String? message;

  /// Postiz: POST JSON to this URL (`postiz_login.url`).
  final String? postizLoginUrl;
  final Map<String, dynamic>? postizLoginBody;

  /// Chatwoot: load this page and submit `chatwoot_login.body` (`login_page_url`).
  final String? chatwootLoginPageUrl;
  final Map<String, dynamic>? chatwootLoginBody;

  const PlatformEmbedSession({
    required this.authorizationUrl,
    this.message,
    this.postizLoginUrl,
    this.postizLoginBody,
    this.chatwootLoginPageUrl,
    this.chatwootLoginBody,
  });

  bool get isPostiz =>
      postizLoginUrl != null &&
      postizLoginUrl!.isNotEmpty &&
      postizLoginBody != null;

  bool get isChatwoot =>
      chatwootLoginPageUrl != null &&
      chatwootLoginPageUrl!.isNotEmpty &&
      chatwootLoginBody != null;

  factory PlatformEmbedSession.fromPostizAutoLogin(Map<String, dynamic> json) {
    return PlatformEmbedSession.fromApiJson(json, loginKey: 'postiz_login');
  }

  factory PlatformEmbedSession.fromSocialConnect(Map<String, dynamic> json) {
    return PlatformEmbedSession.fromApiJson(json, loginKey: 'postiz_login');
  }

  factory PlatformEmbedSession.fromChatwoot(Map<String, dynamic> json) {
    return PlatformEmbedSession.fromApiJson(json, loginKey: 'chatwoot_login');
  }

  factory PlatformEmbedSession.fromApiJson(
    Map<String, dynamic> json, {
    required String loginKey,
  }) {
    final authUrl = (json['authorization_url'] ?? '').toString();
    final loginRaw = json[loginKey];
    Map<String, dynamic>? loginMap;
    if (loginRaw is Map) {
      loginMap = Map<String, dynamic>.from(loginRaw);
    }

    if (loginKey == 'postiz_login') {
      final url = (loginMap?['url'] ?? '').toString();
      final body = loginMap?['body'];
      return PlatformEmbedSession(
        authorizationUrl: authUrl,
        message: json['message']?.toString(),
        postizLoginUrl: url.isEmpty ? null : url,
        postizLoginBody: body is Map ? Map<String, dynamic>.from(body) : null,
      );
    }

    final pageUrl = (loginMap?['login_page_url'] ?? '').toString();
    final body = loginMap?['body'];
    return PlatformEmbedSession(
      authorizationUrl: authUrl,
      message: json['message']?.toString(),
      chatwootLoginPageUrl: pageUrl.isEmpty ? null : pageUrl,
      chatwootLoginBody: body is Map ? Map<String, dynamic>.from(body) : null,
    );
  }
}
