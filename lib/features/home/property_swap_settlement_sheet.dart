import 'package:swappro/barrel.dart';

/// Price-difference settlement overlay (Figma "Frame 54542", node 1:795).
class PropertySwapSettlementSheet extends StatelessWidget {
  const PropertySwapSettlementSheet({
    super.key,
    required this.yourProperty,
    required this.otherProperty,
  });

  final PropertyDetailData yourProperty;
  final PropertyDetailData otherProperty;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _ink = Color(0xFF111111);
  static const Color _bodyInk = Color(0xFF0F111D);
  static const Color _priceLower = Color(0xFF731A39);
  static const Color _priceHigher = Color(0xFF1A8118);

  static Future<void> show(
    BuildContext context, {
    required PropertyDetailData yourProperty,
    required PropertyDetailData otherProperty,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => PropertySwapSettlementSheet(
        yourProperty: yourProperty,
        otherProperty: otherProperty,
      ),
    );
  }

  String? get _yourImage =>
      yourProperty.imageUrls.isNotEmpty ? yourProperty.imageUrls.first : null;

  String? get _otherImage => otherProperty.imageUrls.isNotEmpty
      ? otherProperty.imageUrls.first
      : null;

  double? get _yourAmount => _parsePrice(yourProperty.price);
  double? get _otherAmount => _parsePrice(otherProperty.price);

  bool get _hasPriceMismatch {
    final yours = _yourAmount;
    final other = _otherAmount;
    if (yours == null || other == null) return true;
    return (yours - other).abs() > 0.01;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final yoursLower = _amountIsLower(_yourAmount, _otherAmount);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSwapVisual(),
                  const SizedBox(height: 8),
                  _buildTitlesRow(),
                  const SizedBox(height: 12),
                  _buildPricesRow(yoursLower: yoursLower),
                  if (_hasPriceMismatch) ...[
                    const SizedBox(height: 16),
                    Text(
                      'The transaction is not a perfect match because of '
                      'price difference',
                      textAlign: TextAlign.center,
                      style: AppTypography.style(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _bodyInk,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Do you agree to make topup payment for this transaction?',
                      textAlign: TextAlign.center,
                      style: AppTypography.style(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: _bodyInk,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildAgreeButton(
                    context,
                    label: _hasPriceMismatch
                        ? 'Agree Difference Settlement'
                        : 'Confirm Swap',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwapVisual() {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PropertyThumb(
                  imageUrl: _yourImage,
                  width: 165,
                  height: 125,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PropertyThumb(
                  imageUrl: _otherImage,
                  width: 165,
                  height: 125,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.swap_calls,
              size: 32,
              color: _gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitlesRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            yourProperty.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.style(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            otherProperty.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTypography.style(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricesRow({required bool yoursLower}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _formatDisplayPrice(yourProperty.price),
            style: AppTypography.style(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: yoursLower ? _priceLower : _priceHigher,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            _formatDisplayPrice(otherProperty.price),
            textAlign: TextAlign.right,
            style: AppTypography.style(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: yoursLower ? _priceHigher : _priceLower,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  void _goToConfirmDash(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: const PropertySwapConfirmDashPage(),
      ),
    );
  }

  Widget _buildAgreeButton(BuildContext context, {required String label}) {
    return GestureDetector(
      onTap: () => _goToConfirmDash(context),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_backspace,
              color: Colors.white,
              size: 26,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }

  static double? _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  static bool _amountIsLower(double? a, double? b) {
    if (a == null || b == null) return true;
    return a < b;
  }

  static String _formatDisplayPrice(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.startsWith('₵') ||
        trimmed.startsWith('\$') ||
        trimmed.startsWith('GH')) {
      return trimmed;
    }
    return '₵ $trimmed';
  }
}

class _PropertyThumb extends StatelessWidget {
  const _PropertyThumb({
    required this.imageUrl,
    required this.width,
    required this.height,
    this.alignEnd = false,
  });

  final String? imageUrl;
  final double width;
  final double height;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final child = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: height,
        child: imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
    if (alignEnd) {
      return Align(alignment: Alignment.topRight, child: child);
    }
    return child;
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF5F5F8),
      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF787676)),
    );
  }
}
