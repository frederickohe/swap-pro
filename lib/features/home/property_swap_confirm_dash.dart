import 'package:swappro/barrel.dart';

/// Final swap review — side-by-side comparison (Figma "Swap Dash 3", node 1:177).
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

  String? get _otherHeroImage => otherProperty.imageUrls.isNotEmpty
      ? otherProperty.imageUrls.first
      : null;

  double? get _yourAmount => _parsePrice(yourProperty.price);
  double? get _otherAmount => _parsePrice(otherProperty.price);

  bool get _yoursLower => _amountIsLower(_yourAmount, _otherAmount);

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
              child: AppScreenTopBar(title: 'Confirm Swap'),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroSplit(),
                    const SizedBox(height: 20),
                    _buildPricesRow(),
                    const SizedBox(height: 14),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Expanded(child: _HeroImage(url: _yourHeroImage)),
                  Expanded(child: _HeroImage(url: _otherHeroImage)),
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
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 31),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  yourProperty.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.style(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.15,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricesRow() {
    const barWidth = 22.0;
    const maxBarHeight = 72.0;
    const minBarHeight = 24.0;

    final yourAmount = _yourAmount;
    final otherAmount = _otherAmount;
    final yoursLower = _yoursLower;

    final lowerColor = _priceLower;
    final higherColor = _priceHigher;

    final max = () {
      if (yourAmount == null || otherAmount == null) return null;
      return yourAmount > otherAmount ? yourAmount : otherAmount;
    }();

    double barHeight(double? value) {
      if (value == null || max == null || max <= 0) return 48.0;
      final ratio = (value / max).clamp(0.0, 1.0);
      return minBarHeight + (maxBarHeight - minBarHeight) * ratio;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 27),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PriceBarColumn(
              price: _formatDisplayPrice(yourProperty.price),
              barHeight: barHeight(yourAmount),
              barWidth: barWidth,
              maxBarHeight: maxBarHeight,
              color: yoursLower ? lowerColor : higherColor,
              alignEnd: false,
            ),
          ),
          Expanded(
            child: _PriceBarColumn(
              price: _formatDisplayPrice(otherProperty.price),
              barHeight: barHeight(otherAmount),
              barWidth: barWidth,
              maxBarHeight: maxBarHeight,
              color: yoursLower ? higherColor : lowerColor,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSwap(BuildContext context) async {
    if (submitting) return;

    final cubit = context.read<SwapRequestCubit>();
    final created = await cubit.submit();
    if (!context.mounted) return;

    if (created != null) {
      cubit.reset();
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          duration: const Duration(milliseconds: 350),
          reverseDuration: const Duration(milliseconds: 300),
          child: const PropertySwapCompletePage(),
        ),
      );
      return;
    }

    final message = cubit.state.error;
    if (message != null && message.isNotEmpty) {
      context.showAppSnackBar(message);
    }
  }

  Widget _buildConfirmButton(BuildContext context) {
    return GestureDetector(
      onTap: submitting ? null : () => _submitSwap(context),
      child: Opacity(
        opacity: submitting ? 0.6 : 1,
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
                child: Center(
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Confirm Swap',
                          style: AppTypography.style(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              if (!submitting)
                const Icon(
                  Icons.keyboard_backspace,
                  color: Colors.white,
                  size: 26,
                  textDirection: TextDirection.rtl,
                ),
            ],
          ),
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

class _PriceBarColumn extends StatelessWidget {
  const _PriceBarColumn({
    required this.price,
    required this.barHeight,
    required this.barWidth,
    required this.maxBarHeight,
    required this.color,
    required this.alignEnd,
  });

  final String price;
  final double barHeight;
  final double barWidth;
  final double maxBarHeight;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final crossAlign =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAlign,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          price,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: AppTypography.style(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: color,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: maxBarHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: barWidth,
              height: barHeight,
              color: color,
            ),
          ),
        ),
      ],
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

