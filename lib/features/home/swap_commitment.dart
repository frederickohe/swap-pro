import 'package:swappro/barrel.dart';

/// Commitment payment — Figma "Commitment" (node 1:775).
class SwapCommitmentPage extends StatelessWidget {
  const SwapCommitmentPage({
    super.key,
    required this.propertyTitle,
    this.propertySubtitle,
  });

  final String propertyTitle;
  final String? propertySubtitle;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBg = Color(0xFFF5F4F8);
  static const Color _ink = Color(0xFF111111);
  static const Color _accentGreen = Color(0xFF176B02);

  static const String _termsText =
      'By continuing you agree to our service credit terms. '
      'Paid credits are non-refundable and expire one year from purchase date.';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 8, 20, 0),
              child: _buildTopBar(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(29, 16, 29, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction Details',
                      style: AppTypography.style(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 51 / 22,
                      ),
                    ),
                    if (propertySubtitle != null && propertySubtitle!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        propertyTitle,
                        style: AppTypography.style(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        propertySubtitle!,
                        style: AppTypography.style(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF787676),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      _termsText,
                      style: AppTypography.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 55),
                    _buildPaymentSection(),
                    const SizedBox(height: 24),
                    _buildAccountSection(),
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

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 65,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => _goHome(context),
              child: Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: _backBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: _gold,
                ),
              ),
            ),
          ),
          Text(
            'Swap Bay',
            style: AppTypography.style(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 29 / 20,
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: UserAvatar(size: 65, onLightBackground: true),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    'Visa Card',
                    style: AppTypography.style(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      height: 25 / 16,
                    ),
                  ),
                  const SizedBox(width: 30),
                  Container(
                    width: 24,
                    height: 24,
                    color: const Color(0xFFD9D9D9),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_drop_down,
                      size: 20,
                      color: Color(0xFF1C1B1F),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {},
              child: Text(
                'Add New +',
                style: AppTypography.style(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _accentGreen,
                  height: 25 / 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _summaryRow(
          left: 'Description',
          right: 'Swap Transaction Commitment Fee',
        ),
        const SizedBox(height: 20),
        _summaryRow(left: 'Estimated Tax', right: 'GHC 0.00'),
        const SizedBox(height: 20),
        _summaryRow(left: 'Estimated Total', right: 'GHC 25.00'),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailRow('Account Details', '****1339 1001'),
        const SizedBox(height: 10),
        _detailRow('EXP', '01 / 2026'),
        const SizedBox(height: 10),
        _detailRow('CVV', '776'),
      ],
    );
  }

  Widget _summaryRow({required String left, required String right}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            left,
            style: AppTypography.style(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 20 / 15,
            ),
          ),
        ),
        Text(
          right,
          textAlign: TextAlign.right,
          style: AppTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _accentGreen,
            height: 18 / 14,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.style(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              height: 25 / 16,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.style(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _accentGreen,
            height: 30 / 18,
          ),
        ),
      ],
    );
  }

  Widget _buildPayNowButton(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => _payNow(context),
        child: Container(
          width: 277,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
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

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageTransition(
        type: PageTransitionType.leftToRightWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: const Home(),
      ),
      (route) => false,
    );
  }

  void _payNow(BuildContext context) {
    Navigator.of(context).pop(SwapBayTab.sent);
    context.showAppSnackBar('Payment submitted for $propertyTitle');
  }
}
