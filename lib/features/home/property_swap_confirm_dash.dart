import 'package:swappro/barrel.dart';
import 'package:swappro/common_design/widgets/slide_to_confirm_swap_button.dart';
import 'package:swappro/features/home/swap_success_reveal_route.dart';

/// Final swap review — side-by-side comparison (Figma "Swap Dash 4", node 1:252).
class PropertySwapConfirmDashPage extends StatelessWidget {
  const PropertySwapConfirmDashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SwapRequestCubit, SwapRequestState>(
      builder: (context, state) {
        final yourProperty = state.offer;
        final otherProperty = state.target;

        if (yourProperty == null || otherProperty == null) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Swap details are incomplete.'),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _PropertySwapConfirmDashBody(
          yourProperty: yourProperty,
          otherProperty: otherProperty,
          submitting: state.submitting,
          error: state.error,
        );
      },
    );
  }
}

class _PropertySwapConfirmDashBody extends StatelessWidget {
  const _PropertySwapConfirmDashBody({
    required this.yourProperty,
    required this.otherProperty,
    required this.submitting,
    this.error,
  });

  final PropertyDetailData yourProperty;
  final PropertyDetailData otherProperty;
  final bool submitting;
  final String? error;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _ink = Color(0xFF111111);
  static const Color _priceLower = Color(0xFF731A39);
  static const Color _priceHigher = Color(0xFF1A8118);

  String? get _yourHeroImage =>
      yourProperty.imageUrls.isNotEmpty ? yourProperty.imageUrls.first : null;

  String? get _otherHeroImage =>
      otherProperty.imageUrls.isNotEmpty ? otherProperty.imageUrls.first : null;

  double? get _yourAmount => _parsePrice(yourProperty.price);
  double? get _otherAmount => _parsePrice(otherProperty.price);

  bool get _yoursLower => _amountIsLower(_yourAmount, _otherAmount);

  bool get _pricesMatch {
    final yours = _yourAmount;
    final other = _otherAmount;
    if (yours == null || other == null) return false;
    return (yours - other).abs() <= 0.01;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 8, 15, 0),
              child: AppScreenTopBar(title: 'Confirm Swap', centerTitle: true),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeroSplit(),
                    const SizedBox(height: 28),
                    _buildPropertyIconsRow(),
                    const SizedBox(height: 24),
                    _buildTitlesRow(),
                    const SizedBox(height: 34),
                    _buildPricesRow(),
                    const SizedBox(height: 44),
                    _buildComparisonDetails(),
                    if (error != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 31),
                        child: Text(
                          error!,
                          style: AppTypography.style(
                            fontSize: 13,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 24 + bottomInset),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(39, 0, 39, 16 + bottomInset),
              child: _buildConfirmButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSplit() {
    const height = 278.0;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(child: _HeroImage(url: _yourHeroImage)),
          Expanded(child: _HeroImage(url: _otherHeroImage)),
        ],
      ),
    );
  }

  static const String _yourPropertyIconAsset =
      'assets/img/yourpropertyicon.png';
  static const String _otherPropertyIconAsset =
      'assets/img/otherpropertyicon.png';

  Widget _buildPropertyIconsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 31),
      child: SizedBox(
        height: 88,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _PropertyIconAsset(path: _yourPropertyIconAsset),
                const Spacer(),
                _PropertyIconAsset(path: _otherPropertyIconAsset),
              ],
            ),
            Transform.rotate(
              angle: 1.5708,
              child: const Icon(Icons.swap_calls, size: 42, color: _gold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitlesRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 31),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              yourProperty.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1.15,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              otherProperty.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricesRow() {
    const barHeight = 8.0;
    const minFillFraction = 0.18;

    final yourAmount = _yourAmount;
    final otherAmount = _otherAmount;
    final yoursLower = _yoursLower;
    final pricesMatch = _pricesMatch;

    final lowerColor = _priceLower;
    final higherColor = _priceHigher;

    final max = () {
      if (yourAmount == null || otherAmount == null) return null;
      return yourAmount > otherAmount ? yourAmount : otherAmount;
    }();

    double fillFraction(double? value) {
      if (pricesMatch) return 1.0;
      if (value == null || max == null || max <= 0) return minFillFraction;
      final ratio = (value / max).clamp(0.0, 1.0);
      return minFillFraction + (1 - minFillFraction) * ratio;
    }

    final yourColor = pricesMatch
        ? higherColor
        : (yoursLower ? lowerColor : higherColor);
    final otherColor = pricesMatch
        ? higherColor
        : (yoursLower ? higherColor : lowerColor);

    final yourPrice = _formatDisplayPrice(yourProperty.price);
    final otherPrice = _formatDisplayPrice(otherProperty.price);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 31),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PriceLabel(
                  price: yourPrice,
                  color: yourColor,
                  alignEnd: false,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _PriceLabel(
                  price: otherPrice,
                  color: otherColor,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _PriceTrack(
            fillFraction: fillFraction(yourAmount),
            barHeight: barHeight,
            color: yourColor,
          ),
          const SizedBox(height: 14),
          _PriceTrack(
            fillFraction: fillFraction(otherAmount),
            barHeight: barHeight,
            color: otherColor,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 31),
      child: Column(
        children: [
          _detailRow(
            label: 'Category',
            icon: Icons.category_outlined,
            left: yourProperty.category,
            right: otherProperty.category,
          ),
          const SizedBox(height: 36),
          _detailRow(
            label: 'Location',
            icon: Icons.location_on_outlined,
            left: yourProperty.locationArea,
            right: otherProperty.locationArea,
          ),
          const SizedBox(height: 36),
          _detailRow(
            label: 'Listed',
            icon: Icons.calendar_today_outlined,
            left: yourProperty.date,
            right: otherProperty.date,
          ),
          const SizedBox(height: 36),
          _detailRow(
            label: 'Condition',
            icon: Icons.verified_outlined,
            left: yourProperty.status,
            right: otherProperty.status,
          ),
          const SizedBox(height: 36),
          _detailRow(
            label: 'Receipts',
            icon: Icons.receipt_long_outlined,
            left: yourProperty.receipts,
            right: otherProperty.receipts,
          ),
        ],
      ),
    );
  }

  Widget _detailRow({
    required String label,
    required IconData icon,
    required String left,
    required String right,
  }) {
    return _ComparisonDetailRow(
      left: _SwapDetailCell(
        icon: icon,
        label: label,
        value: _displayValue(left),
      ),
      right: _SwapDetailCell(
        icon: icon,
        label: label,
        value: _displayValue(right),
        alignEnd: true,
      ),
    );
  }

  static String _displayValue(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed == '—') return '—';
    return trimmed;
  }

  Future<void> _submitSwap(BuildContext context) async {
    if (submitting) return;

    final cubit = context.read<SwapRequestCubit>();
    final created = await cubit.submit();
    if (!context.mounted) return;

    if (created != null) {
      cubit.reset();
      Navigator.of(context).pushReplacement(SwapSuccessRevealRoute());
      return;
    }

    final message = cubit.state.error;
    if (message != null && message.isNotEmpty) {
      context.showAppSnackBar(message);
    }
  }

  Widget _buildConfirmButton(BuildContext context) {
    return SlideToConfirmSwapButton(
      loading: submitting,
      enabled: !submitting,
      trackColor: _ink,
      height: 62,
      onConfirm: () => _submitSwap(context),
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
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return '—';
    if (trimmed.startsWith('GH₵')) {
      trimmed = '₵${trimmed.substring(3)}';
    } else if (trimmed.startsWith('GH')) {
      trimmed = trimmed.substring(2).trimLeft();
    }
    if (trimmed.startsWith('₵') || trimmed.startsWith('\$')) {
      return trimmed;
    }
    return '₵ $trimmed';
  }
}

class _ComparisonDetailRow extends StatelessWidget {
  const _ComparisonDetailRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 24),
        Expanded(child: right),
      ],
    );
  }
}

class _SwapDetailCell extends StatelessWidget {
  const _SwapDetailCell({
    required this.icon,
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool alignEnd;

  static const Color _gold = Color(0xFFC3B649);

  @override
  Widget build(BuildContext context) {
    final crossAlign = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.right : TextAlign.left;

    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: _gold),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: textAlign,
                style: AppTypography.style(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: AppTypography.style(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _PropertyIconAsset extends StatelessWidget {
  const _PropertyIconAsset({required this.path});

  final String path;

  static const double _width = 90;
  static const double _height = 64;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, e, s) => const Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: Color(0xFFC3B649),
        ),
      ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({
    required this.price,
    required this.color,
    required this.alignEnd,
  });

  final String price;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          price,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: AppTypography.style(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _PriceTrack extends StatelessWidget {
  const _PriceTrack({
    required this.fillFraction,
    required this.barHeight,
    required this.color,
  });

  final double fillFraction;
  final double barHeight;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final fillWidth = trackWidth * fillFraction.clamp(0.0, 1.0);
        final radius = BorderRadius.circular(barHeight / 2);

        return SizedBox(
          width: trackWidth,
          height: barHeight,
          child: Stack(
            children: [
              Container(
                width: trackWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: radius,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: fillWidth,
                  height: barHeight,
                  decoration: BoxDecoration(color: color, borderRadius: radius),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(
        color: const Color(0xFFE8E8E8),
        child: const Icon(Icons.image_outlined, size: 40),
      );
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, e, s) => Container(
        color: const Color(0xFFE8E8E8),
        child: const Icon(Icons.image_outlined),
      ),
    );
  }
}
