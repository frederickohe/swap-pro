import 'package:swappro/barrel.dart';

/// Swap confirm step — Figma "SwapProp2" (node 1:472).
class PropertySwapConfirmPage extends StatelessWidget {
  const PropertySwapConfirmPage({super.key, required this.data});

  final PropertyDetailData data;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _ink = Color(0xFF111111);
  static const Color _backBg = Color(0xFFF5F4F8);
  static const Color _titleInk = Color(0xFF121111);
  static const Color _inkSoft = Color(0xFF787676);
  static const Color _heartBg = Color(0xFF292526);
  static const Color _star = Color(0xFFFFD33C);

  static const String _trustMessage =
      'To foster trust and guarantee the safety of our community '
      'members, we strongly encourage all users to verify their identity.';

  String get _imageUrl =>
      data.imageUrls.isNotEmpty ? data.imageUrls.first : '';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _gold,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(19, 8, 25, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 78),
              Text(
                'Confirm Other Property',
                textAlign: TextAlign.center,
                style: AppTypography.style(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 26),
              Center(child: _buildProductCard()),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _trustMessage,
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildConfirmButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 65,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildBackButton(context),
          ),
          Text(
            'Swapping',
            style: AppTypography.style(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: UserAvatar(size: 65),
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

  Widget _buildProductCard() {
    return Container(
      width: 155,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: SizedBox(
              height: 251,
              width: 155,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE8E8E8),
                      child: const Icon(
                        Icons.image_outlined,
                        color: _inkSoft,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: _heartBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 8, 5, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _titleInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.category,
                  style: AppTypography.style(
                    fontSize: 12,
                    color: _inkSoft,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      data.price,
                      style: AppTypography.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _heartBg,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.star, size: 18, color: _star),
                    const SizedBox(width: 4),
                    Text(
                      '5.0',
                      style: AppTypography.style(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _heartBg,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeftWithFade,
            duration: const Duration(milliseconds: 350),
            reverseDuration: const Duration(milliseconds: 300),
            child: PropertySwapSelectPage(otherProperty: data),
          ),
        );
      },
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          'Confirm Other Property',
          style: AppTypography.style(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
