import 'package:swappro/barrel.dart';

/// Swap flow — choose a belonging from your listings (Figma "Select Belonging", node 1:599).
class PropertySwapSelectBelongingPage extends StatefulWidget {
  const PropertySwapSelectBelongingPage({
    super.key,
    required this.otherProperty,
  });

  final PropertyDetailData otherProperty;

  @override
  State<PropertySwapSelectBelongingPage> createState() =>
      _PropertySwapSelectBelongingPageState();
}

class _PropertySwapSelectBelongingPageState
    extends State<PropertySwapSelectBelongingPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _divider = Color(0xFFF6F6F6);
  static const Color _searchBorder = Color(0xFFECECF3);
  static const Color _menuBorder = Color(0xFFDFDFDF);

  late final ApiService _apiService = ApiService(
    httpClient: SessionAwareHttpClient(tokenService: TokenService()),
  );

  final TextEditingController _searchController = TextEditingController();

  List<_BelongingRow> _allListings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadListings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadListings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _apiService.listProducts();
      if (!mounted) return;
      final rows = products
          .map(_BelongingRow.fromProduct)
          .where((r) => r.title.trim().isNotEmpty)
          .toList();
      setState(() {
        _allListings = rows.isEmpty ? List.of(_demoListings) : rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _allListings = List.of(_demoListings);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const List<_BelongingRow> _demoListings = [
    _BelongingRow(
      title: '3 Bedroom Apartment',
      subtitle: 'Apartment',
      price: '\$230,000',
    ),
    _BelongingRow(
      title: 'BMW Forza 2020',
      subtitle: 'Dress modern',
      price: '\$520,000.99',
    ),
    _BelongingRow(
      title: 'Hanjing C Ship',
      subtitle: 'Apartment',
      price: '\$150 M',
    ),
    _BelongingRow(
      title: 'Single Room Self Contained',
      subtitle: 'Apartment',
      price: '\$110,000',
    ),
  ];

  List<_BelongingRow> get _visibleListings {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _allListings;
    return _allListings
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.subtitle.toLowerCase().contains(q) ||
              item.price.toLowerCase().contains(q),
        )
        .toList();
  }

  void _onSelect(_BelongingRow item) {
    final yours = propertyDetailFromBelonging(
      title: item.title,
      subtitle: item.subtitle,
      price: item.price,
      imageUrl: item.imageUrl,
    );
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: PropertySwapConfirmYoursPage(
          yourProperty: yours,
          otherProperty: widget.otherProperty,
        ),
      ),
    );
  }

  void _showListingActions(_BelongingRow item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('View listing'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.showAppSnackBar('View ${item.title} coming soon');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
              child: _buildTopBar(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildSearchHeader(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  _error!,
                  style: AppTypography.style(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: SwapproLoadingIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadListings,
                      child: _buildList(),
                    ),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.keyboard_backspace,
                size: 28,
                color: Color(0xFF1C1B1F),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 66),
            child: Text(
              'Listed Properties',
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

  Widget _buildSearchHeader() {
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
              style: AppTypography.style(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search ...',
                hintStyle: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: () => context.showAppSnackBar('Menu coming soon'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _menuBorder),
            ),
            child: const Icon(Icons.menu, size: 22, color: _price),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    final items = _visibleListings;
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
        children: [
          Text(
            'No listings match your search.',
            textAlign: TextAlign.center,
            style: AppTypography.style(fontSize: 14, color: _subtitle),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 13.5),
        child: Divider(color: _divider, height: 1, thickness: 1),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _BelongingListTile(
          item: item,
          onSelect: () => _onSelect(item),
          onMore: () => _showListingActions(item),
        );
      },
    );
  }
}

class _BelongingRow {
  const _BelongingRow({
    required this.title,
    required this.subtitle,
    required this.price,
    this.imageUrl,
    this.productId,
  });

  final String title;
  final String subtitle;
  final String price;
  final String? imageUrl;
  final String? productId;

  factory _BelongingRow.fromProduct(Map<String, dynamic> product) {
    final name = (product['name'] ?? product['title'] ?? '').toString().trim();
    final category =
        (product['category'] ?? product['condition'] ?? '').toString().trim();
    final priceStr = _formatPrice(product['price']);

    String? imageUrl;
    final photos = product['photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first?.toString().trim() ?? '';
      if (first.isNotEmpty) imageUrl = first;
    }
    if (imageUrl == null) {
      final fallback =
          (product['image_url'] ?? product['thumbnail'] ?? '').toString().trim();
      if (fallback.isNotEmpty) imageUrl = fallback;
    }

    return _BelongingRow(
      title: name.isEmpty ? 'Untitled listing' : name,
      subtitle: category.isEmpty ? 'Listing' : category,
      price: priceStr,
      imageUrl: imageUrl,
      productId: (product['id'] ?? product['_id'])?.toString(),
    );
  }

  static String _formatPrice(dynamic value) {
    if (value == null) return '';
    if (value is num) {
      final whole = value == value.roundToDouble();
      final text =
          whole ? value.round().toString() : value.toStringAsFixed(2);
      return '\$$text';
    }
    final s = value.toString().trim();
    if (s.isEmpty) return '';
    return s.startsWith('\$') ? s : '\$$s';
  }
}

class _BelongingListTile extends StatelessWidget {
  const _BelongingListTile({
    required this.item,
    required this.onSelect,
    required this.onMore,
  });

  final _BelongingRow item;
  final VoidCallback onSelect;
  final VoidCallback onMore;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _dark = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    const thumb = 70.0;
    return SizedBox(
      height: 71,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: thumb,
              height: thumb,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, e, s) => _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.style(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _inkTitle,
                          height: 18 / 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: AppTypography.style(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: _subtitle,
                          height: 13 / 12,
                        ),
                      ),
                      const Spacer(),
                      if (item.price.isNotEmpty)
                        Text(
                          item.price,
                          style: AppTypography.style(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _price,
                            height: 18 / 14,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: onMore,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.more_horiz,
                          size: 24,
                          color: _price,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: onSelect,
                      child: Container(
                        width: 50,
                        height: 27,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _dark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Select',
                          style: AppTypography.style(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 17 / 12,
                          ),
                        ),
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

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFFF5F5F8),
      child: const Icon(Icons.image_outlined, color: _subtitle),
    );
  }
}
