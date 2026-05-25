import 'package:swappro/barrel.dart';

/// Final swap review — side-by-side comparison (Figma "Swap Dash 3", node 1:177).
class PropertySwapConfirmDashPage extends StatelessWidget {
  const PropertySwapConfirmDashPage({
    super.key,
    required this.yourProperty,
    required this.otherProperty,
  });

  final PropertyDetailData yourProperty;
  final PropertyDetailData otherProperty;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _ink = Color(0xFF111111);
  static const Color _backBg = Color(0xFFF5F4F8);
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
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 8, 20, 0),
              child: _buildTopBar(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroSplit(),
                    const SizedBox(height: 24),
                    _buildCompareSection(),
                    const SizedBox(height: 20),
                    _buildPricesRow(),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 31),
                      child: _buildSpecRows(),
                    ),
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

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 65,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          _buildBackButton(context),
          Padding(
            padding: const EdgeInsets.only(left: 63),
            child: Text(
              'Confirm Swap',
              style: AppTypography.style(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 29 / 20,
              ),
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

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
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
    );
  }

  Widget _buildHeroSplit() {
    const height = 278.0;
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: _HeroImage(url: _yourHeroImage),
          ),
          Expanded(
            child: _HeroImage(url: _otherHeroImage),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 31),
      child: SizedBox(
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SmallThumb(imageUrl: _yourHeroImage),
                const Spacer(),
                _SmallThumb(imageUrl: _otherHeroImage, alignEnd: true),
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
                Icons.swap_horiz,
                size: 32,
                color: _gold,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
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
        ),
      ),
    );
  }

  Widget _buildPricesRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 27),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatDisplayPrice(yourProperty.price),
              style: AppTypography.style(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _yoursLower ? _priceLower : _priceHigher,
                height: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _formatDisplayPrice(otherProperty.price),
              textAlign: TextAlign.right,
              style: AppTypography.style(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _yoursLower ? _priceHigher : _priceLower,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRows() {
    return Column(
      children: [
        _CompareSpecRow(
          icon: Icons.apartment_outlined,
          leftLabel: 'Type',
          leftValue: _typeLabel(yourProperty.category),
          rightLabel: 'Type',
          rightValue: _typeLabel(otherProperty.category),
        ),
        const SizedBox(height: 24),
        _CompareSpecRow(
          icon: Icons.crop_free,
          leftLabel: 'Covered Area',
          leftValue: _areaLabel(yourProperty.status),
          rightLabel: 'Covered Area',
          rightValue: _areaLabel(otherProperty.status),
        ),
        const SizedBox(height: 24),
        _CompareSpecRow(
          icon: Icons.calendar_today_outlined,
          leftLabel: 'Date',
          leftValue: _dateLabel(yourProperty.date),
          rightLabel: 'Date',
          rightValue: _dateLabel(otherProperty.date),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeftWithFade,
            duration: const Duration(milliseconds: 350),
            reverseDuration: const Duration(milliseconds: 300),
            child: const PropertySwapCompletePage(),
          ),
        );
      },
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
                child: Text(
                  'Confirm Swap',
                  style: AppTypography.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
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

  static String _typeLabel(String category) {
    final t = category.trim();
    return t.isEmpty ? '—' : t;
  }

  static String _areaLabel(String status) {
    final t = status.trim();
    if (t.isEmpty) return '—';
    if (t.toLowerCase().contains('sqr') || t.toLowerCase().contains('ft')) {
      return t;
    }
    return t;
  }

  static String _dateLabel(String date) {
    final t = date.trim();
    return t.isEmpty ? '—' : t;
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

class _SmallThumb extends StatelessWidget {
  const _SmallThumb({required this.imageUrl, this.alignEnd = false});

  final String? imageUrl;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 100,
        height: 76,
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
      return Align(alignment: Alignment.topRight, child: thumb);
    }
    return thumb;
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF5F5F8),
      child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF787676)),
    );
  }
}

class _CompareSpecRow extends StatelessWidget {
  const _CompareSpecRow({
    required this.icon,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final IconData icon;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SpecCell(
            icon: icon,
            label: leftLabel,
            value: leftValue,
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _SpecCell(
            icon: icon,
            label: rightLabel,
            value: rightValue,
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

class _SpecCell extends StatelessWidget {
  const _SpecCell({
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
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22, color: _gold),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment:
                alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (alignEnd) {
      return Align(alignment: Alignment.topRight, child: content);
    }
    return content;
  }
}
