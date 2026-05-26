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

  late final TextEditingController _searchController;
  late String _activeQuery;

  SearchFiltersResult? _filters;
  List<_SearchProduct> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _activeQuery = widget.query?.trim() ?? '';
    _searchController = TextEditingController(text: _activeQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchResults());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchResults() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = context.read<ApiService>();
      double? minValue;
      double? maxValue;
      if (_filters != null) {
        if (_filters!.minPrice > 0) minValue = _filters!.minPrice;
        if (_filters!.maxPrice > 0) maxValue = _filters!.maxPrice;
      }

      final result = await api.searchListings(
        keyword: _activeQuery.isEmpty ? null : _activeQuery,
        minValue: minValue,
        maxValue: maxValue,
        page: 1,
        size: 40,
      );
      if (!mounted) return;

      final items = result['items'];
      final cards = <_SearchProduct>[];
      if (items is List) {
        for (var i = 0; i < items.length; i++) {
          final raw = items[i];
          if (raw is! Map) continue;
          cards.add(
            _SearchProduct.fromListing(
              Map<String, dynamic>.from(raw),
              imageHeight: i.isOdd ? 251 : 217,
            ),
          );
        }
      }

      setState(() => _products = cards);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString();
      if (message.contains('Session expired') ||
          message.toLowerCase().contains('invalid token')) {
        context.showAppSnackBar('Session expired. Please sign in again.');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const Signin()),
          (route) => route.isFirst,
        );
        return;
      }
      setState(() {
        _error = message;
        _products = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applySearch() {
    FocusScope.of(context).unfocus();
    setState(() => _activeQuery = _searchController.text.trim());
    _fetchResults();
  }

  Future<void> _openFilters() async {
    final result = await Navigator.push<SearchFiltersResult>(
      context,
      MaterialPageRoute(builder: (_) => const SearchFiltersPage()),
    );
    if (result != null && mounted) {
      setState(() => _filters = result);
      _fetchResults();
    }
  }

  List<_SearchProduct> get _leftColumn {
    final left = <_SearchProduct>[];
    for (var i = 0; i < _products.length; i += 2) {
      left.add(_products[i]);
    }
    return left;
  }

  List<_SearchProduct> get _rightColumn {
    final right = <_SearchProduct>[];
    for (var i = 1; i < _products.length; i += 2) {
      right.add(_products[i]);
    }
    return right;
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
    final filteredLeft = _leftColumn;
    final filteredRight = _rightColumn;
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
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(21, 8, 21, 0),
                child: Text(
                  _error!,
                  style: _textStyle(size: 12, color: Colors.red.shade700),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: SwapproLoadingIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchResults,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 29, 20, 24),
                        child: hasResults
                            ? _buildMasonryGrid(filteredLeft, filteredRight)
                            : _buildEmptyState(),
                      ),
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
            style: _textStyle(
              size: 22,
              weight: FontWeight.w400,
              color: Colors.black,
            ),
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
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
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
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _applySearch,
                  behavior: HitTestBehavior.opaque,
                  child: const Icon(Icons.search, size: 20, color: _ink),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 30),
        GestureDetector(
          onTap: _openFilters,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _filters != null ? _gold : _menuBorder,
                width: _filters != null ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.tune, size: 22, color: _ink),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final queryLabel = _activeQuery.isEmpty ? 'listings' : '"$_activeQuery"';
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Text(
          'No results for $queryLabel',
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

const _kListingImageFallback =
    'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400&q=80';

class _SearchProduct {
  final String id;
  final String title;
  final String location;
  final String price;
  final double rating;
  final String imageUrl;
  final double imageHeight;
  final Map<String, dynamic>? listingJson;

  const _SearchProduct({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.imageHeight,
    this.listingJson,
  });

  factory _SearchProduct.fromListing(
    Map<String, dynamic> json, {
    required double imageHeight,
  }) {
    final id = (json['id'] ?? '').toString();
    final title = (json['title'] ?? '').toString();
    final category = (json['category'] ?? '').toString().trim();
    final condition = (json['condition'] ?? '').toString().trim();
    final location = category.isNotEmpty
        ? category
        : (condition.isNotEmpty ? condition : 'Listing');

    final value = json['estimated_value'];
    final price = value is num
        ? 'GH₵ ${value.toStringAsFixed(2)}'
        : (value?.toString().trim().isNotEmpty == true ? 'GH₵ $value' : '—');

    final displayUrl = listingDisplayImageUrl(json);

    return _SearchProduct(
      id: id.isEmpty ? title : id,
      title: title.isEmpty ? 'Untitled listing' : title,
      location: location,
      price: price,
      rating: 5.0,
      imageUrl: displayUrl ?? _kListingImageFallback,
      imageHeight: imageHeight,
      listingJson: json,
    );
  }
}

class _SearchProductCard extends StatelessWidget {
  final _SearchProduct data;

  const _SearchProductCard({required this.data});

  Future<void> _openDetail(BuildContext context) async {
    if (data.listingJson != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailPage(
            data: PropertyDetailData.fromListing(data.listingJson!),
          ),
        ),
      );
      return;
    }
    if (data.id.isEmpty) return;
    try {
      final listing = await context.read<ApiService>().getListing(data.id);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PropertyDetailPage(data: PropertyDetailData.fromListing(listing)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      context.showAppSnackBar(e.toString());
    }
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
              child: Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE8E8E8),
                  child: const Icon(Icons.image_outlined, color: _inkSoft),
                ),
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
            style: AppTypography.style(fontSize: 12, color: _inkSoft),
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
