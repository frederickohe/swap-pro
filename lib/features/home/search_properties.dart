import 'package:swappro/barrel.dart';
import 'package:swappro/features/home/listing_location.dart';

/// Figma "Search" frame (node 162:1864) — search results grid.
class SearchPropertiesPage extends StatefulWidget {
  const SearchPropertiesPage({super.key, this.query});

  final String? query;

  @override
  State<SearchPropertiesPage> createState() => _SearchPropertiesPageState();
}

class _SearchPropertiesPageState extends State<SearchPropertiesPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _price = Color(0xFF292526);
  static const Color _searchBorder = Color(0xFFECECF3);
  static const Color _menuBorder = Color(0xFFDFDFDF);
  static const Color _divider = Color(0xFFF6F6F6);

  late final TextEditingController _searchController;
  late String _activeQuery;

  SearchFiltersResult? _filters;
  List<_SearchProduct> _products = [];
  bool _loading = true;
  String? _error;
  /// `false` = horizontal row cards; `true` = stacked masonry grid.
  bool _isGridView = true;

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
      String? location;
      double? lat;
      double? lng;
      double? radiusKm;
      String? category;
      String? condition;
      if (_filters != null) {
        category = _filters!.category;
        condition = _filters!.condition;
        if (_filters!.minPrice > 0) minValue = _filters!.minPrice;
        if (_filters!.maxPrice > 0) maxValue = _filters!.maxPrice;
        final locationText = _filters!.location.trim();
        if (_filters!.locationLat != null && _filters!.locationLng != null) {
          lat = _filters!.locationLat;
          lng = _filters!.locationLng;
          radiusKm = _filters!.locationRadiusKm;
        } else if (locationText.isNotEmpty) {
          location = locationText;
        }
      }

      final result = await api.searchListings(
        keyword: _activeQuery.isEmpty ? null : _activeQuery,
        category: category,
        condition: condition,
        location: location,
        minValue: minValue,
        maxValue: maxValue,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        page: 1,
        size: 40,
      );
      if (!mounted) return;

      final items = result['items'];
      final listings = <Map<String, dynamic>>[];
      if (items is List) {
        for (final raw in items) {
          if (raw is Map) listings.add(Map<String, dynamic>.from(raw));
        }
      }
      await prefetchListingLocations(listings);

      final cards = <_SearchProduct>[];
      for (var i = 0; i < listings.length; i++) {
        cards.add(
          _SearchProduct.fromListing(
            listings[i],
            imageHeight: i.isOdd ? 251 : 217,
          ),
        );
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 15, 0),
                  child: AppScreenTopBar(
                    title: 'Search Properties',
                    titleStyle: AppTypography.style(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildSearchHeader(),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                          child: _buildResultsList(),
                        ),
                ),
              ],
            ),
            Positioned(
              right: 38,
              bottom: 24 + bottomInset,
              child: _buildFilterFab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Row(
      children: [
        Expanded(child: _buildSearchField()),
        const SizedBox(width: 30),
        _buildMenuButton(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _searchBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: _textStyle(size: 14, weight: FontWeight.w400),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applySearch(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search ...',
                hintStyle: _textStyle(
                  size: 14,
                  color: _ink.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _applySearch,
            behavior: HitTestBehavior.opaque,
            child: const Icon(Icons.search, size: 18, color: _ink),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => setState(() => _isGridView = !_isGridView),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _menuBorder),
          ),
          child: Icon(
            _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            size: 22,
            color: _price,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterFab() {
    return Material(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(45),
      child: InkWell(
        borderRadius: BorderRadius.circular(45),
        onTap: _openFilters,
        child: const SizedBox(
          width: 70,
          height: 60,
          child: Icon(Icons.tune, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (_products.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
        children: [_buildEmptyState()],
      );
    }

    if (_isGridView) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
        child: _buildMasonryGrid(_leftColumn, _rightColumn),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 120),
      itemCount: _products.length,
      separatorBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 27),
        child: Divider(color: _divider, height: 1, thickness: 1),
      ),
      itemBuilder: (context, index) {
        return _SearchListTile(data: _products[index]);
      },
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
  final String imageUrl;
  final double imageHeight;
  final Map<String, dynamic>? listingJson;

  const _SearchProduct({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
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
    final location = listingDisplayLocation(json);

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
      imageUrl: displayUrl ?? _kListingImageFallback,
      imageHeight: imageHeight,
      listingJson: json,
    );
  }
}

class _SearchListTile extends StatelessWidget {
  const _SearchListTile({required this.data});

  final _SearchProduct data;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _inkSoft = Color(0xFF787676);
  static const Color _priceInk = Color(0xFF292526);
  static const double _thumbW = 255;
  static const double _thumbH = 217;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _SearchProductCard.openDetail(context, data),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              width: _thumbW,
              height: _thumbH,
              child: Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFF5F5F8),
                  child: const Icon(Icons.image_outlined, color: _inkSoft),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: SizedBox(
              height: _thumbH,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _inkTitle,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data.location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(fontSize: 12, color: _inkSoft),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.price,
                    style: AppTypography.style(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _priceInk,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchProductCard extends StatelessWidget {
  final _SearchProduct data;

  const _SearchProductCard({required this.data});

  static Future<void> openDetail(BuildContext context, _SearchProduct data) async {

    if (data.listingJson != null) {
      await prefetchListingLocations([data.listingJson!]);
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailPage(
            data: PropertyDetailData.fromListing(data.listingJson!),
            showSwapThis: true,
          ),
        ),
      );
      return;
    }
    if (data.id.isEmpty) return;
    try {
      final listing = await context.read<ApiService>().getListing(data.id);
      if (!context.mounted) return;
      await prefetchListingLocations([listing]);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailPage(
            data: PropertyDetailData.fromListing(listing),
            showSwapThis: true,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      context.showAppSnackBar(e.toString());
    }
  }

  static const Color _inkSoft = Color(0xFF787676);
  static const Color _heartBg = Color(0xFF292526);
  static const Color _titleInk = Color(0xFF121111);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openDetail(context, data),
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
          Text(
            data.price,
            style: AppTypography.style(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _heartBg,
            ),
          ),
        ],
      ),
    );
  }
}
