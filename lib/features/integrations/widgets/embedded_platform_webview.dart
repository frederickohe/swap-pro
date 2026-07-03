import 'package:swappro/barrel.dart';
import 'package:swappro/features/integrations/webview_url_resolver.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens Postiz or Chatwoot using credentials returned by the swappro API,
/// then navigates to [PlatformEmbedSession.authorizationUrl] to link channels.
class EmbeddedPlatformWebView extends StatefulWidget {
  final String title;
  final PlatformEmbedSession session;

  const EmbeddedPlatformWebView({
    super.key,
    required this.title,
    required this.session,
  });

  @override
  State<EmbeddedPlatformWebView> createState() =>
      _EmbeddedPlatformWebViewState();
}

class _EmbeddedPlatformWebViewState extends State<EmbeddedPlatformWebView> {
  late final WebViewController _controller;
  var _loading = true;
  var _loginStepDone = false;
  String? _error;

  PlatformEmbedSession get _session => widget.session;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) async {
            if (!mounted) return;
            setState(() => _loading = false);
            if (!_loginStepDone && _session.isChatwoot) {
              await _tryChatwootFormSubmit();
            }
          },
          onWebResourceError: (err) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _error = err.description;
            });
          },
        ),
      );
    _startLoginFlow();
  }

  Future<void> _startLoginFlow() async {
    final auth = resolveEmbeddedPlatformUrl(_session.authorizationUrl.trim());
    if (auth.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing authorization URL from server.';
      });
      return;
    }

    if (_session.isPostiz) {
      final loginUrl = resolveEmbeddedPlatformUrl(
        _session.postizLoginUrl!.trim(),
      );
      final body = _session.postizLoginBody!;
      // Must be a JSON string for fetch(); a JS object becomes "[object Object]".
      final bodyJsonString = jsonEncode(body);
      final html =
          '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"></head>
<body style="font-family:sans-serif;padding:24px;text-align:center;">
<p>Signing you in to Postiz…</p>
<script>
(async function() {
  try {
    const res = await fetch(${jsonEncode(loginUrl)}, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      credentials: 'include',
      body: ${jsonEncode(bodyJsonString)}
    });
    if (!res.ok) {
      const text = await res.text();
      throw new Error(text || ('HTTP ' + res.status));
    }
    window.location.replace(${jsonEncode(auth)});
  } catch (e) {
    const msg = (e && e.message) ? e.message : 'Sign-in failed';
    document.body.innerHTML = '<p style="color:#b91c1c">' + msg + '</p><p style="font-size:12px;color:#666">Close and try again.</p>';
  }
})();
</script>
</body>
</html>
''';
      _loginStepDone = true;
      await _controller.loadHtmlString(html, baseUrl: loginUrl);
      return;
    }

    if (_session.isChatwoot) {
      final pageUrl = resolveEmbeddedPlatformUrl(
        _session.chatwootLoginPageUrl!.trim(),
      );
      await _controller.loadRequest(Uri.parse(pageUrl));
      return;
    }

    await _controller.loadRequest(Uri.parse(auth));
    _loginStepDone = true;
  }

  Future<void> _tryChatwootFormSubmit() async {
    final body = _session.chatwootLoginBody;
    if (body == null) return;
    final email = (body['email'] ?? '').toString();
    final password = (body['password'] ?? '').toString();
    if (email.isEmpty || password.isEmpty) return;

    final script =
        '''
(function() {
  var email = ${jsonEncode(email)};
  var password = ${jsonEncode(password)};
  var emailInput = document.querySelector('input[type="email"], input[name="email"], #email');
  var passInput = document.querySelector('input[type="password"], input[name="password"], #password');
  if (!emailInput || !passInput) return 'no_form';
  emailInput.value = email;
  emailInput.dispatchEvent(new Event('input', { bubbles: true }));
  passInput.value = password;
  passInput.dispatchEvent(new Event('input', { bubbles: true }));
  var form = emailInput.closest('form');
  if (form) { form.submit(); return 'submitted'; }
  var btn = document.querySelector('button[type="submit"], input[type="submit"]');
  if (btn) { btn.click(); return 'clicked'; }
  return 'no_submit';
})();
''';
    try {
      final result = await _controller.runJavaScriptReturningResult(script);
      final s = result.toString();
      if (s.contains('submitted') || s.contains('clicked')) {
        _loginStepDone = true;
        await Future<void>.delayed(const Duration(milliseconds: 800));
        final auth = resolveEmbeddedPlatformUrl(
          _session.authorizationUrl.trim(),
        );
        if (auth.isNotEmpty) {
          await _controller.loadRequest(Uri.parse(auth));
        }
      }
    } catch (_) {}
  }

  Future<void> _openAuthorizationPage() async {
    final auth = resolveEmbeddedPlatformUrl(_session.authorizationUrl.trim());
    if (auth.isNotEmpty) {
      await _controller.loadRequest(Uri.parse(auth));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: AppTypography.style(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _openAuthorizationPage,
            child: Text(
              'Continue',
              style: AppTypography.style(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: SwapproLoadingIndicator(size: 32)),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Material(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: AppTypography.style(
                      color: Colors.red.shade900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fetches a Postiz or Chatwoot embed session and opens the WebView.
Future<void> openEmbeddedPlatformSession(
  BuildContext context, {
  required String title,
  required Future<PlatformEmbedSession> Function() fetchSession,
}) async {
  try {
    final session = await fetchSession();
    if (!context.mounted) return;
    if (session.authorizationUrl.trim().isEmpty) {
      context.showAppSnackBar('Server did not return a link URL.');
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EmbeddedPlatformWebView(title: title, session: session),
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    context.showAppSnackBar(e.toString().replaceFirst('Exception: ', ''));
  }
}
