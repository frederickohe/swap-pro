import 'package:swappro/barrel.dart';

/// Figma "Search" frame (node 162:1864) — search results grid.
class SearchPropertiesPage extends StatefulWidget {
  const SearchPropertiesPage({super.key, this.query});

  final String? query;

  @override
  State<SearchPropertiesPage> createState() => _SearchPropertiesPageState();
}

class _SearchPropertiesPageState extends State<SearchPropertiesPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _searchBorder = Color(0xFFECECF3);
  static const Color _menuBorder = Color(0xFFDFDFDF);
  static const Color _backBg = Color(0xFFF5F4F8);
  static const Color _gold = Color(0xFFC3B649);

  static const _leftColumn = [
    _SearchProduct(
      title: '2 Bedroom Self C',
      location: 'Lapaz',
      price: '\$212.99',
      rating: 5.0,
      imageUrl:
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400&q=80',
      imageHeight: 217,
    ),
    _SearchProduct(
      title: 'Aquarius G Yatch',
      location: 'Achimota',
      price: '\$194.99',
      rating: 5.0,
      imageUrl:
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&q=80',
      imageHeight: 217,
    ),
    _SearchProduct(
      title: '2 Bedroom Self C',
      location: 'Building',
      price: '\$212.99',
      rating: 5.0,
      imageUrl:
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=400&q=80',
      imageHeight: 217,
    ),
  ];

  static const _rightColumn = [
    _SearchProduct(
      title: 'BMW Forza 2020',
      location: 'North Kaneshie',
      price: '₵662.99',
      rating: 5.0,
      imageUrl:
          'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=400&q=80',
      imageHeight: 251,
    ),
    _SearchProduct(
      title: 'Audi Zatron',
      location: 'Kasoa',
      price: '\$122.99',
      rating: 5.0,
      imageUrl:
          'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?w=400&q=80',
      imageHeight: 251,
    ),
  ];

  late final TextEditingController _searchController;
  late String _activeQuery;

  @override
  void initState() {
    super.initState();
    _activeQuery = widget.query?.trim() ?? '';
    _searchController = TextEditingController(text: _activeQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    setState(() => _activeQuery = _searchController.text.trim());
  }

  bool _matchesQuery(_SearchProduct product) {
    if (_activeQuery.isEmpty) return true;
    final q = _activeQuery.toLowerCase();
    return product.title.toLowerCase().contains(q) ||
        product.location.toLowerCase().contains(q);
  }

  TextStyle _textStyle({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _ink,
  }) {
    return AppTypography.style(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: 1.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLeft =
        _leftColumn.where(_matchesQuery).toList(growable: false);
    final filteredRight =
        _rightColumn.where(_matchesQuery).toList(growable: false);
    final hasResults = filteredLeft.isNotEmpty || filteredRight.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildTopBar(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 20, 21, 0),
              child: _buildSearchHeader(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 29, 20, 24),
                child: hasResults
                    ? _buildMasonryGrid(filteredLeft, filteredRight)
                    : _buildEmptyState(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SizedBox(
      height: 50,
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
            'Search Properties',
            style: _textStyle(size: 22, weight: FontWeight.w600, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: _searchBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: _textStyle(size: 14, weight: FontWeight.w500),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applySearch(),
              decoration: InputDecoration(
                hintText: 'Search ...',
                hintStyle: _textStyle(
                  size: 14,
                  weight: FontWeight.w500,
                  color: _ink.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchFiltersPage()),
            );
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _menuBorder),
            ),
            child: const Icon(Icons.menu, size: 22, color: _ink),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Text(
          'No results for "$_activeQuery"',
          textAlign: TextAlign.center,
          style: _textStyle(size: 16, color: _ink.withValues(alpha: 0.6)),
        ),
      ),
    );
  }

  Widget _buildMasonryGrid(
    List<_SearchProduct> left,
    List<_SearchProduct> right,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildColumn(left, const [0, 24, 40])),
        const SizedBox(width: 45),
        Expanded(child: _buildColumn(right, const [0, 24])),
      ],
    );
  }

  Widget _buildColumn(List<_SearchProduct> products, List<double> topGaps) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[];
    for (var i = 0; i < products.length; i++) {
      if (i > 0 && i < topGaps.length) {
        children.add(SizedBox(height: topGaps[i]));
      } else if (i > 0) {
        children.add(const SizedBox(height: 24));
      }
      children.add(_SearchProductCard(data: products[i]));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _SearchProduct {
  final String title;
  final String location;
  final String price;
  final double rating;
  final String imageUrl;
  final double imageHeight;

  const _SearchProduct({
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.imageHeight,
  });
}

class _SearchProductCard extends StatelessWidget {
  final _SearchProduct data;

  const _SearchProductCard({required this.data});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyDetailPage(
          data: PropertyDetailData.demo(
            title: data.title,
            price: data.price,
            imageUrl: data.imageUrl,
            location: data.location,
          ),
        ),
      ),
    );
  }

  static const Color _inkSoft = Color(0xFF787676);
  static const Color _heartBg = Color(0xFF292526);
  static const Color _star = Color(0xFFFFD33C);
  static const Color _titleInk = Color(0xFF121111);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: data.imageHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  data.imageUrl,
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
        const SizedBox(height: 8),
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
          data.location,
          style: AppTypography.style(
            fontSize: 12,
            color: _inkSoft,
          ),
        ),
        const SizedBox(height: 8),
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
              data.rating.toStringAsFixed(1),
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
    );
  }
}
