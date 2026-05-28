import 'package:swappro/barrel.dart';

/// Swap flow — pick your listing to offer (Figma "Swap Middle", node 1:759).
class PropertySwapSelectPage extends StatefulWidget {
  const PropertySwapSelectPage({super.key, required this.otherProperty});

  final PropertyDetailData otherProperty;

  @override
  State<PropertySwapSelectPage> createState() => _PropertySwapSelectPageState();
}

class _PropertySwapSelectPageState extends State<PropertySwapSelectPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _inkSoft = Color(0xFF787676);
  static const Color _divider = Color(0xFFF6F6F6);

  late final ApiService _apiService = ApiService(
    httpClient: SessionAwareHttpClient(tokenService: TokenService()),
  );

  List<_SelectableListing> _listings = [];
  bool _loading = true;
  String? _error;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadListings();
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
          .map(_SelectableListing.fromProduct)
          .where((r) => r.title.trim().isNotEmpty)
          .toList();
      setState(() {
        _listings = rows.isEmpty ? List.of(_demoListings) : rows;
        _selectedIndex = rows.isEmpty ? null : 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _listings = List.of(_demoListings);
        _selectedIndex = 0;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const List<_SelectableListing> _demoListings = [
    _SelectableListing(
      title: 'BMW Forza 2020',
      subtitle: 'Dress modern',
      price: '\$520,000.99',
    ),
    _SelectableListing(
      title: '3 Bedroom Apartment',
      subtitle: 'Apartment',
      price: '\$230,000',
    ),
    _SelectableListing(
      title: 'Hanjing C Ship',
      subtitle: 'Apartment',
      price: '\$150 M',
    ),
  ];

  void _onProceed() {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: PropertySwapSelectBelongingPage(
          otherProperty: widget.otherProperty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 36),
              Text(
                'Select Your Property',
                style: AppTypography.style(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  height: 51 / 32,
                ),
              ),

              const SizedBox(height: 20),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    style: AppTypography.style(
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              Expanded(child: _buildListingsBody()),
              const SizedBox(height: 16),
              _buildProceedButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return AppScreenTopBar(
      title: 'Swapping',
      centerTitle: false,
      titleStyle: AppTypography.style(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.black,
        height: 29 / 24,
      ),
    );
  }

  Widget _buildListingsBody() {
    if (_loading) {
      return const Center(child: SwapproLoadingIndicator());
    }
    if (_listings.isEmpty) {
      return Center(
        child: Text(
          'You have no listings yet.\nAdd a belonging to start swapping.',
          textAlign: TextAlign.center,
          style: AppTypography.style(
            fontSize: 15,
            color: _inkSoft,
            height: 1.45,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: _listings.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: _divider, height: 1, thickness: 1),
      ),
      itemBuilder: (context, index) {
        final item = _listings[index];
        final selected = _selectedIndex == index;
        return _SelectableListingTile(
          item: item,
          selected: selected,
          onTap: () => setState(() => _selectedIndex = index),
        );
      },
    );
  }

  Widget _buildProceedButton() {
    final enabled = !_loading;
    return Center(
      child: GestureDetector(
        onTap: enabled ? _onProceed : null,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.45,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 277,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Proceed',
              style: AppTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 24 / 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectableListing {
  const _SelectableListing({
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

  factory _SelectableListing.fromProduct(Map<String, dynamic> product) {
    final name = (product['name'] ?? product['title'] ?? '').toString().trim();
    final category = (product['category'] ?? product['condition'] ?? '')
        .toString()
        .trim();
    final rawPrice = product['price'];
    final priceStr = _formatPrice(rawPrice);

    String? imageUrl;
    final photos = product['photos'];
    if (photos is List && photos.isNotEmpty) {
      final first = photos.first?.toString().trim() ?? '';
      if (first.isNotEmpty) imageUrl = first;
    }
    if (imageUrl == null) {
      final fallback = (product['image_url'] ?? product['thumbnail'] ?? '')
          .toString()
          .trim();
      if (fallback.isNotEmpty) imageUrl = fallback;
    }

    return _SelectableListing(
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
      final text = whole ? value.round().toString() : value.toStringAsFixed(2);
      return '\$$text';
    }
    final s = value.toString().trim();
    if (s.isEmpty) return '';
    return s.startsWith('\$') ? s : '\$$s';
  }
}

class _SelectableListingTile extends StatelessWidget {
  const _SelectableListingTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _SelectableListing item;
  final bool selected;
  final VoidCallback onTap;

  static const Color _titleInk = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _gold = Color(0xFFC3B649);

  @override
  Widget build(BuildContext context) {
    const thumb = 70.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? _gold : Colors.transparent,
              width: 2,
            ),
          ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _titleInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: AppTypography.style(
                        fontSize: 12,
                        color: _subtitle,
                      ),
                    ),
                    if (item.price.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.price,
                        style: AppTypography.style(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _price,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? _gold : _subtitle,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      color: const Color(0xFFE8E8E8),
      child: const Icon(Icons.image_outlined, color: _subtitle),
    );
  }
}
