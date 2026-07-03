import 'package:swappro/barrel.dart';

/// Full-screen property gallery — Figma "Prop 2 Img" (node 191:412).
class PropertySwapImagePage extends StatefulWidget {
  const PropertySwapImagePage({
    super.key,
    required this.data,
    this.initialIndex = 0,
  });

  final PropertyDetailData data;
  final int initialIndex;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBg = Color(0xFFF5F4F8);
  static const Color _ink = Color(0xFF000000);

  @override
  State<PropertySwapImagePage> createState() => _PropertySwapImagePageState();
}

class _PropertySwapImagePageState extends State<PropertySwapImagePage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    final max = widget.data.imageUrls.length;
    _selectedIndex = max == 0
        ? 0
        : widget.initialIndex.clamp(0, max - 1);
  }

  String get _mainImageUrl {
    final urls = widget.data.imageUrls;
    if (urls.isEmpty) return '';
    return urls[_selectedIndex];
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.data.imageUrls;
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppScaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildMainImage(),
          Positioned(
            top: topInset + 18,
            left: 14,
            child: _buildBackButton(context),
          ),
          if (urls.length > 1)
            Positioned(
              right: 18,
              bottom: bottomInset + 24,
              child: _buildThumbnailStrip(urls),
            ),
        ],
      ),
    );
  }

  Widget _buildMainImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Image.network(
        _mainImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFE8E8E8),
          child: const Icon(
            Icons.image_outlined,
            size: 48,
            color: PropertySwapImagePage._ink,
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return SettingsScreenBackButton(onPressed: () => Navigator.pop(context));
  }

  Widget _buildThumbnailStrip(List<String> urls) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < urls.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: _ThumbnailTile(
                imageUrl: urls[i],
                selected: i == _selectedIndex,
              ),
            ),
          ],
        ],
      ),
    );
  }

}

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({
    required this.imageUrl,
    required this.selected,
  });

  final String imageUrl;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 93,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white,
          width: selected ? 3.5 : 2.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7.5),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFFE8E8E8),
            child: const Icon(Icons.image_outlined, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
