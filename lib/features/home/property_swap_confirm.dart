import 'package:swappro/barrel.dart';

/// Swap confirm step — Figma "SwapProp2" (node 1:472).
class PropertySwapConfirmPage extends StatelessWidget {
  const PropertySwapConfirmPage({super.key, required this.data});

  final PropertyDetailData data;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _ink = Color(0xFF111111);
  static const Color _titleInk = Color(0xFF121111);
  static const Color _inkSoft = Color(0xFF787676);
  static const Color _heartBg = Color(0xFF292526);

  String get _imageUrl => data.imageUrls.isNotEmpty ? data.imageUrls.first : '';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppScaffold(
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
                'Interested in this property?',
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
              const SizedBox(height: 30),
              _buildConfirmButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppScreenTopBar(
      title: 'Swapping',
      lightScreen: true,
      titleStyle: AppTypography.style(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
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
              child: Image.network(
                _imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE8E8E8),
                  child: const Icon(Icons.image_outlined, color: _inkSoft),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(5, 8, 5, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _titleInk,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.style(fontSize: 12, color: _inkSoft),
                ),
                const SizedBox(height: 12),
                Text(
                  data.price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _heartBg,
                  ),
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
        context.read<SwapRequestCubit>().start(target: data);
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeftWithFade,
            duration: const Duration(milliseconds: 350),
            reverseDuration: const Duration(milliseconds: 300),
            child: const ListingsPage(swapSelectMode: true),
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
          'Confirm',
          style: AppTypography.style(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
