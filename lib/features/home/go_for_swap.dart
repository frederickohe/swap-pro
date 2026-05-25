import 'package:swappro/barrel.dart';

/// Swap meet-up details + map — Figma "Swap 12" (node 1:788).
class GoForSwapPage extends StatelessWidget {
  const GoForSwapPage({
    super.key,
    required this.propertyTitle,
    this.swapLocation = 'Dzorwulu Swap Hub',
    this.swapDate = '30 /02 / 2025',
    this.swapTime = '9 : 30 GMT',
  });

  final String propertyTitle;
  final String swapLocation;
  final String swapDate;
  final String swapTime;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBg = Color(0xFFF5F4F8);
  static const Color _accentGreen = Color(0xFF176B02);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 20, 0),
                  child: _buildTopBar(context),
                ),
                const SizedBox(height: 34),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildDetailsSection(),
                ),
                const SizedBox(height: 53),
              ],
            ),
          ),
          Expanded(child: _buildMapSection()),
        ],
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

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _detailRow(label: 'Swap Location', value: swapLocation),
        const SizedBox(height: 20),
        _detailRow(label: 'Swap Date', value: swapDate),
        const SizedBox(height: 20),
        _detailRow(label: 'Swap Time', value: swapTime),
      ],
    );
  }

  Widget _detailRow({required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.style(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 20 / 15,
            ),
          ),
        ),
        Text(
          value,
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

  Widget _buildMapSection() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
      child: Image.asset(
        'assets/img/swap_location_map.png',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _mapPlaceholder(),
      ),
    );
  }

  Widget _mapPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8F4E6),
            Color(0xFFD4E8CF),
            Color(0xFFB8D4B0),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 48,
            color: _accentGreen.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              swapLocation,
              textAlign: TextAlign.center,
              style: AppTypography.style(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _accentGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
