import 'package:swappro/barrel.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// In-app Paystack checkout. Pops with the payment reference when checkout completes.
class PaystackCheckoutWebView extends StatefulWidget {
  const PaystackCheckoutWebView({
    super.key,
    required this.authorizationUrl,
    required this.reference,
  });

  final String authorizationUrl;
  final String reference;

  @override
  State<PaystackCheckoutWebView> createState() => _PaystackCheckoutWebViewState();
}

class _PaystackCheckoutWebViewState extends State<PaystackCheckoutWebView> {
  late final WebViewController _controller;
  var _loading = true;
  String? _error;
  var _completed = false;

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
      _error = 'Missing Paystack checkout URL.';
      _loading = false;
    } else {
      _controller.loadRequest(Uri.parse(url));
    }
  }

  void _onUrl(String url) {
    if (!mounted || _completed) return;
    setState(() => _loading = false);

    final lower = url.toLowerCase();
    final ref = widget.reference.trim();
    if (ref.isEmpty) return;

    final hasRef = lower.contains(ref.toLowerCase()) ||
        lower.contains('reference=${Uri.encodeComponent(ref).toLowerCase()}') ||
        lower.contains('trxref=${Uri.encodeComponent(ref).toLowerCase()}');

    final looksSuccessful = lower.contains('success') ||
        lower.contains('callback') ||
        lower.contains('close') ||
        hasRef;

    if (hasRef && looksSuccessful) {
      _completed = true;
      Navigator.of(context).pop(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Paystack',
          style: AppTypography.style(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
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
    );
  }
}
