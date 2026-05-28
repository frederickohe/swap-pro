import 'package:swappro/barrel.dart';

/// Swap flow — confirm your listing (Figma "Belonging2", node 1:555).
class PropertySwapConfirmYoursPage extends StatelessWidget {
  const PropertySwapConfirmYoursPage({super.key});

  static const Color _gold = Color(0xFFC3B649);
  static const Color _ink = Color(0xFF111111);
  static const Color _titleInk = Color(0xFF121111);
  static const Color _inkSoft = Color(0xFF787676);
  static const Color _heartBg = Color(0xFF292526);
  static const Color _star = Color(0xFFFFD33C);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SwapRequestCubit, SwapRequestState>(
      builder: (context, state) {
        final yourProperty = state.offer;
        if (yourProperty == null) {
          return Scaffold(
            backgroundColor: _gold,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No listing selected',
                        textAlign: TextAlign.center,
                        style: AppTypography.style(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Go back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final imageUrl = yourProperty.imageUrls.isNotEmpty
            ? yourProperty.imageUrls.first
            : '';
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
                    'Confirm Your Property',
                    textAlign: TextAlign.center,
                    style: AppTypography.style(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Center(child: _buildProductCard(yourProperty, imageUrl)),
                  const SizedBox(height: 30),
                  _buildConfirmButton(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppScreenTopBar(
      title: 'Swapping',
      lightScreen: false,
      titleStyle: AppTypography.style(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProductCard(PropertyDetailData yourProperty, String imageUrl) {
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
              height: 217,
              width: 155,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFE8E8E8),
                      child: const Icon(Icons.image_outlined, color: _inkSoft),
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
                  yourProperty.title,
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
                  yourProperty.category,
                  style: AppTypography.style(fontSize: 12, color: _inkSoft),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      yourProperty.price,
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

  Widget _buildConfirmButton(BuildContext context, SwapRequestState state) {
    final target = state.target;
    final offer = state.offer;

    return GestureDetector(
      onTap: target == null || offer == null
          ? null
          : () {
              PropertySwapSettlementSheet.show(
                context,
                yourProperty: offer,
                otherProperty: target,
              );
            },
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.25),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          'Confirm Your Property',
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

/// Maps a belonging list row into [PropertyDetailData] for legacy/demo flows.
PropertyDetailData propertyDetailFromBelonging({
  required String title,
  required String subtitle,
  required String price,
  String? imageUrl,
  String? listingId,
}) {
  return PropertyDetailData(
    listingId: listingId,
    title: title,
    description: '',
    imageUrls: imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : const [],
    ownerName: '',
    wishlistItems: const [],
    price: price,
    date: '',
    category: subtitle,
    receipts: '',
    status: '',
  );
}
