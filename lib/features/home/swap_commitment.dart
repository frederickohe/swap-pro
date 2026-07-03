import 'package:swappro/barrel.dart';
import 'package:swappro/features/home/paystack_checkout_webview.dart';

/// Pay transaction fee — opens Paystack, then moves swap to Ready Swap.
class SwapCommitmentPage extends StatefulWidget {
  const SwapCommitmentPage({
    super.key,
    required this.swapRequestId,
    required this.propertyTitle,
    this.propertySubtitle,
    this.feeAmount = 0,
  });

  final String swapRequestId;
  final String propertyTitle;
  final String? propertySubtitle;
  final double feeAmount;

  @override
  State<SwapCommitmentPage> createState() => _SwapCommitmentPageState();
}

class _SwapCommitmentPageState extends State<SwapCommitmentPage> {
  static const Color _gold = Color(0xFFC3B649);
  static const Color _ink = Color(0xFF111111);

  var _paying = false;
  late double _displayFee = widget.feeAmount;

  String get _feeLabel {
    if (_displayFee <= 0) return 'GH₵ —';
    return 'GH₵ ${_displayFee.toStringAsFixed(2)}';
  }

  static double? _feeFromInitResponse(Map<String, dynamic> init) {
    final swap = init['swap_request'];
    Map<String, dynamic>? swapMap;
    if (swap is Map<String, dynamic>) {
      swapMap = swap;
    } else if (swap is Map) {
      swapMap = Map<String, dynamic>.from(swap);
    }
    final raw = swapMap?['initiator_fee_amount'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 8, 15, 0),
              child: AppScreenTopBar(
                title: 'Pay Transaction Fee',
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(29, 24, 29, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay Transaction Fee',
                      style: AppTypography.style(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pay to access receiver\'s details and location.',
                      style: AppTypography.style(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF787676),
                        height: 1.45,
                      ),
                    ),
                    if (widget.propertyTitle.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        widget.propertyTitle,
                        style: AppTypography.style(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                    if (widget.propertySubtitle != null &&
                        widget.propertySubtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.propertySubtitle!,
                        style: AppTypography.style(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF787676),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Transaction fee',
                            style: AppTypography.style(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          _feeLabel,
                          style: AppTypography.style(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF176B02),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(32, 0, 32, 16 + bottomInset),
              child: _buildPayNowButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayNowButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: _paying ? null : () => _payNow(context),
        child: Container(
          width: 277,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _paying ? _ink.withValues(alpha: 0.5) : _ink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: _paying
              ? const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Pay Now',
                  style: AppTypography.style(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 24 / 18,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _payNow(BuildContext context) async {
    final id = widget.swapRequestId.trim();
    if (id.isEmpty) {
      context.showAppSnackBar('Missing swap request.');
      return;
    }

    setState(() => _paying = true);
    final api = context.read<ApiService>();

    try {
      final init = await api.initializeInitiatorFeePayment(id);
      final refreshedFee = _feeFromInitResponse(init);
      if (refreshedFee != null && refreshedFee > 0 && mounted) {
        setState(() => _displayFee = refreshedFee);
      }
      final payment = init['payment'];
      Map<String, dynamic>? paymentMap;
      if (payment is Map<String, dynamic>) {
        paymentMap = payment;
      } else if (payment is Map) {
        paymentMap = Map<String, dynamic>.from(payment);
      }

      final authUrl =
          (paymentMap?['authorization_url'] ?? paymentMap?['authorizationUrl'] ?? '')
              .toString()
              .trim();
      final reference =
          (paymentMap?['reference'] ?? init['reference'] ?? '').toString().trim();
      final callbackUrl =
          (paymentMap?['callback_url'] ?? paymentMap?['callbackUrl'] ?? '')
              .toString()
              .trim();

      if (authUrl.isEmpty || reference.isEmpty) {
        if (!context.mounted) return;
        context.showAppSnackBar(
          'Could not open payment checkout. Refresh Swap Bay and try again.',
        );
        return;
      }

      if (!context.mounted) return;
      final paidRef = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => PaystackCheckoutWebView(
            authorizationUrl: authUrl,
            reference: reference,
            callbackUrl: callbackUrl.isEmpty ? null : callbackUrl,
          ),
        ),
      );

      if (!context.mounted) return;
      if (paidRef == null || paidRef.isEmpty) {
        context.showAppSnackBar('Payment was not completed.');
        return;
      }

      await api.confirmInitiatorFee(paidRef);

      if (!context.mounted) return;
      context.showAppSnackBar(
        'Payment successful. Receiver details were sent to your phone.',
        variant: AppSnackBarVariant.success,
      );
      Navigator.of(context).pop(SwapBayTab.readySwaps);
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      context.showAppSnackBar(msg);
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }
}
