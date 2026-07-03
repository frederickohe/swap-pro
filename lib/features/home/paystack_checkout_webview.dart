import 'package:swappro/barrel.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app Paystack checkout. Pops with the payment reference when checkout completes.
class PaystackCheckoutWebView extends StatefulWidget {
  const PaystackCheckoutWebView({
    super.key,
    required this.authorizationUrl,
    required this.reference,
    this.callbackUrl,
  });

  final String authorizationUrl;
  final String reference;
  /// Server callback URL Paystack redirects to after payment (if configured).
  final String? callbackUrl;

  @override
  State<PaystackCheckoutWebView> createState() => _PaystackCheckoutWebViewState();
}

class _PaystackCheckoutWebViewState extends State<PaystackCheckoutWebView> {
  late final WebViewController _controller;
  var _loading = true;
  String? _error;
  var _completed = false;

  String get _reference => widget.reference.trim();

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Flutter;Webview')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (url) => _onUrl(url),
          onUrlChange: (change) {
            final url = change.url;
            if (url != null) _onUrl(url);
          },
          onWebResourceError: (err) {
            if (!mounted || _completed) return;
            setState(() {
              _loading = false;
              _error = err.description;
            });
          },
        ),
      );

    final url = widget.authorizationUrl.trim();
    if (url.isEmpty) {
      _error = 'Missing payment checkout URL.';
      _loading = false;
    } else {
      _controller.loadRequest(Uri.parse(url));
    }
  }

  void _completeCheckout() {
    if (!mounted || _completed || _reference.isEmpty) return;
    _completed = true;
    Navigator.of(context).pop(_reference);
  }

  void _onUrl(String url) {
    if (!mounted || _completed) return;
    setState(() => _loading = false);
    if (_shouldCompleteForUrl(url)) {
      _completeCheckout();
    }
  }

  bool _shouldCompleteForUrl(String url) {
    if (_reference.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    final path = uri.path.toLowerCase();
    final lower = url.toLowerCase();

    final refParam = (uri.queryParameters['reference'] ??
            uri.queryParameters['trxref'] ??
            '')
        .trim();
    if (refParam.isNotEmpty && refParam == _reference) {
      return true;
    }

    final callback = widget.callbackUrl?.trim();
    if (callback != null && callback.isNotEmpty) {
      final callbackUri = Uri.tryParse(callback);
      if (callbackUri != null) {
        final sameHost = host == callbackUri.host.toLowerCase();
        final callbackPath = callbackUri.path.toLowerCase();
        if (sameHost &&
            (path == callbackPath ||
                path.startsWith('$callbackPath/') ||
                lower.startsWith(callback.toLowerCase()))) {
          return true;
        }
      }
    }

    if (host == 'standard.paystack.co' && path.contains('close')) {
      return true;
    }

    if (host.contains('paystack.com') &&
        (path.contains('success') || lower.contains('successful'))) {
      return true;
    }

    if (lower.contains(_reference.toLowerCase()) &&
        (lower.contains('reference=') ||
            lower.contains('trxref=') ||
            lower.contains('/return') ||
            lower.contains('callback'))) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Payment',
          style: AppTypography.style(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _completed ? null : _completeCheckout,
            child: Text(
              'Done',
              style: AppTypography.style(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _completed ? Colors.grey : const Color(0xFF176B02),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTypography.style(fontSize: 15, color: Colors.black87),
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: SwapproLoadingIndicator()),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 12 + bottomInset),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _completed ? null : _completeCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                "I've completed payment",
                style: AppTypography.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
