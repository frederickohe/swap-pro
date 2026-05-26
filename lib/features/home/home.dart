import 'package:swappro/barrel.dart';

// Figma Dashboard palette
const _kBg = Color(0xFFFFFFFF);
const _kInk = Color(0xFF111111);
const _kInkSoft = Color(0xFF787676);
const _kSearchBorder = Color(0xFFECECF3);
const _kNotifBorder = Color(0xFFDFDFDF);
const _kBadge = Color(0xFFFD5F4A);
const _kNavBg = Color(0xFF111111);
const _kGold = Color(0xFFC3B649);
const _kHeartBg = Color(0xFF292526);
const _kStar = Color(0xFFFFD33C);

class Home extends StatefulWidget {
  const Home({super.key});

  static Route<void> routeFromWelcome() {
    return PageRouteBuilder<void>(
      settings: const RouteSettings(name: 'Home'),
      pageBuilder: (context, animation, secondaryAnimation) => const Home(),
      transitionDuration: const Duration(milliseconds: 1600),
      reverseTransitionDuration: const Duration(milliseconds: 700),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final scaleCurved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInBack,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0, end: 1).animate(curved),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.78, end: 1).animate(scaleCurved),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _navIndex = 0;
  Future<int>? _unreadCountFuture;
  Future<List<_ProductCardData>>? _featuredListingsFuture;
  final TextEditingController _searchController = TextEditingController();

  static const _categories = [
    _CategoryItem('Phone', Icons.smartphone_outlined),
    _CategoryItem('Laptop', Icons.laptop_mac_outlined),
    _CategoryItem('Speakers', Icons.speaker_outlined),
    _CategoryItem('Camera', Icons.camera_alt_outlined),
    _CategoryItem('Clothes', Icons.checkroom_outlined),
    _CategoryItem('Perfumes', Icons.spa_outlined),
    _CategoryItem('Soap', Icons.soap_outlined),
    _CategoryItem('Fan', Icons.mode_fan_off_outlined),
    _CategoryItem('Carpet', Icons.home_outlined),
    _CategoryItem('Light', Icons.lightbulb_outline),
    _CategoryItem('Book', Icons.menu_book_outlined),
    _CategoryItem('Utensils', Icons.restaurant_outlined),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = context.read<ApiService>();
    _unreadCountFuture ??= api.getUnreadNotificationCount();
    _featuredListingsFuture ??= _loadFeaturedListings(api);
  }

  Future<List<_ProductCardData>> _loadFeaturedListings(ApiService api) async {
    final result = await api.searchListings(page: 1, size: 10);
    final items = result['items'];
    if (items is! List || items.isEmpty) return const [];

    final cards = <_ProductCardData>[];
    for (var i = 0; i < items.length; i++) {
      final raw = items[i];
      if (raw is! Map) continue;
      final json = Map<String, dynamic>.from(raw);
      cards.add(
        _ProductCardData.fromListing(json, imageHeight: i.isOdd ? 251 : 217),
      );
    }
    return cards;
  }

  Future<void> _refreshFeaturedListings() async {
    setState(() {
      _featuredListingsFuture = _loadFeaturedListings(
        context.read<ApiService>(),
      );
    });
  }

  void _openSearchResults() {
    final query = _searchController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SearchPropertiesPage(query: query.isEmpty ? null : query),
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _unreadCountFuture = context
          .read<ApiService>()
          .getUnreadNotificationCount();
    });
  }

  TextStyle _textStyle({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _kInk,
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
      backgroundColor: _kBg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: _buildHeader(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 36, 16, 0),
                    child: _buildCategoryGrid(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(23, 36, 23, 0),
                    child: _buildFeaturedHeader(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 120 + bottomInset),
                    child: _buildFeaturedListings(),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 76 + bottomInset,
            child: _buildFabColumn(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 12 + bottomInset,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(child: _buildLocationSearch()),
        const SizedBox(width: 30),
        FutureBuilder<int>(
          future: _unreadCountFuture,
          builder: (context, snap) {
            final unread = snap.data ?? 0;
            return GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsInboxPage(),
                  ),
                );
                await _refreshNotifications();
              },
              child: _NotificationButton(showBadge: unread > 0),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationSearch() {
    return _LocationSearchBar(
      controller: _searchController,
      onSearch: _openSearchResults,
      textStyle: _textStyle,
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 70,
        crossAxisSpacing: 0,
        childAspectRatio: 60 / 54,
      ),
      itemBuilder: (context, index) {
        final cat = _categories[index];
        return _CategoryTile(label: cat.label, icon: cat.icon, onTap: () {});
      },
    );
  }

  Widget _buildFeaturedHeader() {
    return Text(
      'Featured Listings',
      style: _textStyle(size: 22, weight: FontWeight.w600),
    );
  }

  Widget _buildFeaturedListings() {
    return FutureBuilder<List<_ProductCardData>>(
      future: _featuredListingsFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError) {
          return Column(
            children: [
              Text(
                'Could not load listings.',
                style: _textStyle(size: 14, color: _kInkSoft),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _refreshFeaturedListings,
                child: const Text('Retry'),
              ),
            ],
          );
        }
        final products = snap.data ?? const [];
        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No listings available yet.',
              style: _textStyle(size: 14, color: _kInkSoft),
            ),
          );
        }
        return _buildProductRow(products);
      },
    );
  }

  Future<void> _openPropertyDetail(_ProductCardData product) async {
    PropertyDetailData detail;
    if (product.listingJson != null) {
      detail = PropertyDetailData.fromListing(product.listingJson!);
    } else {
      try {
        final listing = await context.read<ApiService>().getListing(product.id);
        if (!mounted) return;
        detail = PropertyDetailData.fromListing(listing);
      } catch (_) {
        if (!mounted) return;
        detail = PropertyDetailData.demo(
          title: product.title,
          price: product.price,
          imageUrl: product.imageUrl,
          location: product.location,
        );
      }
    }
    if (!mounted) return;
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: PropertyDetailPage(data: detail),
      ),
    );
  }

  Widget _buildProductRow(List<_ProductCardData> products) {
    final visible = products.take(2).toList(growable: false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _ProductCard(
              data: visible[i],
              onImageTap: () => _openPropertyDetail(visible[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFabColumn() {
    return _FabCircle(
      icon: Icons.add_circle_outline,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddBelongingPage()),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Center(
      child: Container(
        width: 362,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _kNavBg,
          borderRadius: BorderRadius.circular(44),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selected: _navIndex == 0,
              onTap: () => setState(() => _navIndex = 0),
            ),
            _NavItem(
              icon: Icons.format_list_bulleted,
              selected: _navIndex == 1,
              onTap: () {
                setState(() => _navIndex = 1);
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 350),
                    reverseDuration: const Duration(milliseconds: 300),
                    child: const DashListingsPage(),
                  ),
                ).then((_) {
                  if (mounted) setState(() => _navIndex = 0);
                });
              },
            ),
            _NavItem(
              icon: Icons.swap_horiz,
              selected: _navIndex == 2,
              onTap: () {
                setState(() => _navIndex = 2);
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.rightToLeftWithFade,
                    duration: const Duration(milliseconds: 350),
                    reverseDuration: const Duration(milliseconds: 300),
                    child: const SwapBayPage(initialTab: SwapBayTab.sent),
                  ),
                ).then((_) {
                  if (mounted) setState(() => _navIndex = 0);
                });
              },
            ),
            _NavItem(
              icon: Icons.person_outline,
              selected: _navIndex == 3,
              onTap: () {
                setState(() => _navIndex = 3);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Profile()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final IconData icon;

  const _CategoryItem(this.label, this.icon);
}

class _ProductCardData {
  final String id;
  final String title;
  final String location;
  final String price;
  final double rating;
  final String imageUrl;
  final double imageHeight;
  final Map<String, dynamic>? listingJson;

  const _ProductCardData({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.imageHeight,
    this.listingJson,
  });

  factory _ProductCardData.fromListing(
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
    final fallback =
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400&q=80';

    return _ProductCardData(
      id: id.isEmpty ? title : id,
      title: title.isEmpty ? 'Untitled listing' : title,
      location: location,
      price: price,
      rating: 5.0,
      imageUrl: displayUrl ?? fallback,
      imageHeight: imageHeight,
      listingJson: json,
    );
  }
}

/// Figma "Location Search" (node 159:602) — pin left, compact search cluster right.
class _LocationSearchBar extends StatelessWidget {
  const _LocationSearchBar({
    required this.controller,
    required this.onSearch,
    required this.textStyle,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final TextStyle Function({double size, FontWeight weight, Color color})
  textStyle;

  static const double _height = 50;
  static const double _iconSize = 15;
  static const double _searchIconSize = 14;
  static const double _textSize = 12;
  static const double _clusterGap = 23;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _kSearchBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _FilledLocationPin(size: _iconSize),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 72, maxWidth: 140),
                child: TextField(
                  controller: controller,
                  style: textStyle(
                    size: _textSize,
                    weight: FontWeight.w500,
                    color: _kInk,
                  ),
                  textAlign: TextAlign.left,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search ...',
                    hintStyle: textStyle(
                      size: _textSize,
                      weight: FontWeight.w300,
                      color: _kInk,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    isCollapsed: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: _clusterGap),
              GestureDetector(
                onTap: onSearch,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  Icons.search,
                  size: _searchIconSize,
                  color: _kInk,
                  weight: 600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Filled black map pin with white center dot (Figma Icon / Location).
class _FilledLocationPin extends StatelessWidget {
  const _FilledLocationPin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FilledLocationPinPainter(color: _kInk),
        size: Size(size, size),
      ),
    );
  }
}

class _FilledLocationPinPainter extends CustomPainter {
  _FilledLocationPinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pinPath = Path()
      ..moveTo(w * 0.5, h * 0.92)
      ..cubicTo(w * 0.22, h * 0.58, w * 0.08, h * 0.42, w * 0.08, h * 0.28)
      ..arcToPoint(
        Offset(w * 0.92, h * 0.28),
        radius: Radius.circular(w * 0.42),
        clockwise: true,
      )
      ..cubicTo(w * 0.92, h * 0.42, w * 0.78, h * 0.58, w * 0.5, h * 0.92)
      ..close();

    canvas.drawPath(pinPath, Paint()..color = color);

    final dotCenter = Offset(w * 0.5, h * 0.30);
    canvas.drawCircle(dotCenter, w * 0.14, Paint()..color = Colors.white);
    canvas.drawCircle(
      dotCenter,
      w * 0.14,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.04,
    );
  }

  @override
  bool shouldRepaint(covariant _FilledLocationPinPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _NotificationButton extends StatelessWidget {
  final bool showBadge;

  const _NotificationButton({required this.showBadge});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kBg,
              border: Border.all(color: _kNotifBorder, width: 1.2),
            ),
            child: const Center(
              child: Icon(Icons.notifications_none, size: 22, color: _kInk),
            ),
          ),
          if (showBadge)
            Positioned(
              right: 10,
              top: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kBadge,
                  border: Border.all(color: _kBg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: _kInk),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.style(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _kInk,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _ProductCardData data;
  final VoidCallback onImageTap;

  const _ProductCard({
    required this.data,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: data.imageHeight,
            width: double.infinity,
            child: GestureDetector(
              onTap: onImageTap,
              child: Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFE8E8E8),
                  child: const Icon(Icons.image_outlined, color: _kInkSoft),
                ),
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
            color: const Color(0xFF121111),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.location,
          style: AppTypography.style(fontSize: 12, color: _kInkSoft),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              data.price,
              style: AppTypography.style(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _kHeartBg,
              ),
            ),
            const Spacer(),
            const Icon(Icons.star, size: 16, color: _kStar),
            const SizedBox(width: 4),
            Text(
              data.rating.toStringAsFixed(1),
              style: AppTypography.style(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _kHeartBg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FabCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FabCircle({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: const BoxDecoration(color: _kNavBg, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 50,
        height: 50,
        child: Icon(
          icon,
          color: selected ? _kGold : Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
