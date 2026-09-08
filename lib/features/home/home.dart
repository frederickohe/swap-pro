import 'dart:ui' show ImageFilter;

import 'package:swappro/barrel.dart';
import 'package:swappro/utils/keyboard_dismiss.dart';

// Figma Dashboard palette
const _kBg = Color(0xFFFFFFFF);
const _kInk = Color(0xFF111111);
const _kInkSoft = Color(0xFF787676);
const _kSearchBorder = Color(0xFFECECF3);
const _kNotifBorder = Color(0xFFDFDFDF);
const _kBadge = Color(0xFFFD5F4A);
const _kNavBg = Color(0xFF111111);
const _kHeartBg = Color(0xFF292526);

/// Preloaded dashboard payload so Home can open without a skeleton wait.
class _HomeBootstrapData {
  const _HomeBootstrapData({
    required this.recentPosts,
    required this.unreadCount,
  });

  final List<_ProductCardData> recentPosts;
  final int unreadCount;
}

/// Shows the Lottie loader until dashboard assets are ready, then opens [Home].
class HomeEntry extends StatefulWidget {
  const HomeEntry({super.key});

  @override
  State<HomeEntry> createState() => _HomeEntryState();
}

class _HomeEntryState extends State<HomeEntry> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openHome());
  }

  Future<void> _openHome() async {
    _HomeBootstrapData? bootstrap;
    try {
      final loggedIn = isAuthenticated(context);
      bootstrap = await Home._loadBootstrap(
        context.read<ApiService>(),
        includeNotifications: loggedIn,
      ).timeout(const Duration(seconds: 12));
    } catch (_) {
      bootstrap = null;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => Home(bootstrap: bootstrap)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SwapLottieLoadingPage();
  }
}

class Home extends StatefulWidget {
  const Home({super.key, _HomeBootstrapData? bootstrap})
      : _bootstrap = bootstrap;

  final _HomeBootstrapData? _bootstrap;

  static Future<_HomeBootstrapData> _loadBootstrap(
    ApiService api, {
    bool includeNotifications = true,
  }) async {
    if (!includeNotifications) {
      return _HomeBootstrapData(
        recentPosts: await _fetchRecentPosts(api),
        unreadCount: 0,
      );
    }
    final results = await Future.wait<Object>([
      _fetchRecentPosts(api),
      api.getUnreadNotificationCount(),
    ]);
    return _HomeBootstrapData(
      recentPosts: results[0] as List<_ProductCardData>,
      unreadCount: results[1] as int,
    );
  }

  static Future<List<_ProductCardData>> _fetchRecentPosts(ApiService api) async {
    final result = await api.searchListings(page: 1, size: 100);
    final items = result['items'];
    if (items is! List || items.isEmpty) return const [];

    final listings = <Map<String, dynamic>>[];
    for (final raw in items) {
      if (raw is Map) listings.add(Map<String, dynamic>.from(raw));
    }
    await prefetchListingLocations(listings);

    // Newest first (API already orders by created_at desc; keep stable).
    listings.sort((a, b) {
      final aCreated = (a['created_at'] ?? '').toString();
      final bCreated = (b['created_at'] ?? '').toString();
      return bCreated.compareTo(aCreated);
    });

    final cards = <_ProductCardData>[];
    for (var i = 0; i < listings.length; i++) {
      cards.add(
        _ProductCardData.fromListing(
          listings[i],
          imageHeight: i.isOdd ? 251 : 217,
        ),
      );
    }
    return cards;
  }

  static Route<void> routeFromWelcome() {
    return PageRouteBuilder<void>(
      settings: const RouteSettings(name: 'Home'),
      pageBuilder: (context, animation, secondaryAnimation) => const HomeEntry(),
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
  Future<List<_ProductCardData>>? _recentPostsFuture;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showOnboardingFab = false;

  static const _navIcons = <String>[
    Ph.house_line_duotone,
    Entypo.list,
    Uil.exchange,
    Ph.user,
  ];

  static const _categories = [
    _CategoryItem('Cryptos', 'assets/icons/categories/cryptos.png'),
    _CategoryItem('Services', 'assets/icons/categories/services.png'),
    _CategoryItem('Phones', 'assets/icons/categories/phones.png'),
    _CategoryItem('Laptops', 'assets/icons/categories/laptops.png'),
    _CategoryItem('Cars', 'assets/icons/categories/cars.png'),
    _CategoryItem('Games', 'assets/icons/categories/games.png'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final bootstrap = widget._bootstrap;
    if (bootstrap != null) {
      _unreadCountFuture = Future.value(bootstrap.unreadCount);
      _recentPostsFuture = Future.value(bootstrap.recentPosts);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOnboardingFabVisibility();
      if (widget._bootstrap == null) {
        _loadInitialData();
      }
    });
  }

  Future<void> _loadOnboardingFabVisibility() async {
    try {
      final completed = await OnboardingService().isCompleted();
      if (!mounted) return;
      setState(() => _showOnboardingFab = !completed);
    } catch (_) {
      // Best-effort; never block Home.
    }
  }

  Future<void> _openOnboarding() async {
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FtuOnboardingPage()),
    );
    if (!mounted) return;
    final completed =
        finished == true || await OnboardingService().isCompleted();
    if (completed) {
      setState(() => _showOnboardingFab = false);
    }
  }

  void _loadInitialData() {
    if (!mounted) return;
    final api = context.read<ApiService>();
    final loggedIn = isAuthenticated(context);
    setState(() {
      _unreadCountFuture =
          loggedIn ? api.getUnreadNotificationCount() : Future.value(0);
      _recentPostsFuture = _loadRecentPosts(api);
    });
  }

  Future<List<_ProductCardData>> _loadRecentPosts(ApiService api) {
    return Home._fetchRecentPosts(api);
  }

  Future<void> _onPullRefresh() => _refreshHome();

  Future<void> _refreshHome() async {
    final api = context.read<ApiService>();
    final posts = await _loadRecentPosts(api);
    final unread =
        isAuthenticated(context) ? await api.getUnreadNotificationCount() : 0;
    if (!mounted) return;
    setState(() {
      _recentPostsFuture = Future.value(posts);
      _unreadCountFuture = Future.value(unread);
    });
  }

  void _openSearchResults() {
    dismissAppKeyboard();
    final query = _searchController.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SearchPropertiesPage(query: query.isEmpty ? null : query),
      ),
    );
  }

  void _openCategorySearch(String category) {
    dismissAppKeyboard();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchPropertiesPage(initialCategory: category),
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    if (!isAuthenticated(context)) {
      setState(() => _unreadCountFuture = Future.value(0));
      return;
    }
    setState(() {
      _unreadCountFuture = context
          .read<ApiService>()
          .getUnreadNotificationCount();
    });
  }

  Future<void> _openAccountFeature(Future<void> Function() open) async {
    dismissAppKeyboard();
    if (!await ensureAuthenticated(context)) return;
    if (!mounted) return;
    await open();
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
    const navHeight = 64.0;
    final navBottom = 12.0 + bottomInset;
    final fabBottom = navBottom + navHeight + 12.0;

    return AppScaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                  child: _buildHeader(),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onPullRefresh,
                    child: _buildRecentPostsFeed(120 + bottomInset),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: fabBottom,
            child: _buildFabColumn(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: navBottom,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'What do you want?',
                style: AppTypography.style(
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  color: _kInk,
                  height: 1.15,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    _openAccountFeature(() async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Profile()),
                      );
                    });
                  },
                  child: const _HeaderCircleButton(icon: Ri.user_3_line),
                ),
                const SizedBox(width: 8),
                FutureBuilder<int>(
                  future: _unreadCountFuture,
                  builder: (context, snap) {
                    final unread = snap.data ?? 0;
                    return GestureDetector(
                      onTap: () async {
                        await _openAccountFeature(() async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsInboxPage(),
                            ),
                          );
                          await _refreshNotifications();
                        });
                      },
                      child: _HeaderCircleButton(
                        icon: Ion.notifications_outline,
                        showBadge: unread > 0,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildLocationSearch(),
      ],
    );
  }

  Widget _buildLocationSearch() {
    return _LocationSearchBar(
      controller: _searchController,
      focusNode: _searchFocus,
      onSearch: _openSearchResults,
      textStyle: _textStyle,
    );
  }

  Widget _buildCategoryStrip() {
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return _CategoryTile(
            label: cat.label,
            iconAsset: cat.iconAsset,
            onTap: () => _openCategorySearch(cat.label),
          );
        },
      ),
    );
  }

  Widget _buildRecentPostsHeader() {
    return Text(
      'Recent Posts',
      style: _textStyle(size: 22, weight: FontWeight.w600),
    );
  }

  static const _feedScrollPhysics = AlwaysScrollableScrollPhysics(
    parent: BouncingScrollPhysics(),
  );

  /// Scrollable feed below the fixed header: categories, title, and listings.
  /// Pull-to-refresh reloads listings only; the search bar stays fixed above.
  Widget _buildRecentPostsFeed(double bottomPadding) {
    return FutureBuilder<List<_ProductCardData>>(
      future: _recentPostsFuture,
      builder: (context, snap) {
        late final Widget listingsBody;
        if (snap.connectionState == ConnectionState.waiting) {
          listingsBody = const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (snap.hasError) {
          listingsBody = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load recent posts.',
                style: _textStyle(size: 14, color: _kInkSoft),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _refreshHome,
                child: const Text('Retry'),
              ),
            ],
          );
        } else {
          final products = snap.data ?? const [];
          if (products.isEmpty) {
            listingsBody = Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No posts yet.',
                style: _textStyle(size: 14, color: _kInkSoft),
              ),
            );
          } else {
            listingsBody = _buildProductGrid(products);
          }
        }

        return ListView(
          physics: _feedScrollPhysics,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(bottom: bottomPadding),
          children: [
            const SizedBox(height: 36),
            _buildCategoryStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(23, 36, 23, 0),
              child: _buildRecentPostsHeader(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: listingsBody,
            ),
          ],
        );
      },
    );
  }

  Future<void> _openPropertyDetail(_ProductCardData product) async {
    dismissAppKeyboard();
    PropertyDetailData detail;
    if (product.listingJson != null) {
      await prefetchListingLocations([product.listingJson!]);
      detail = PropertyDetailData.fromListing(product.listingJson!);
    } else {
      try {
        final listing = await context.read<ApiService>().getListing(product.id);
        if (!mounted) return;
        await prefetchListingLocations([listing]);
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
        child: PropertyDetailPage(data: detail, showSwapThis: true),
      ),
    );
  }

  Widget _buildProductGrid(List<_ProductCardData> products) {
    final left = <_ProductCardData>[];
    final right = <_ProductCardData>[];
    for (var i = 0; i < products.length; i++) {
      if (i.isEven) {
        left.add(products[i]);
      } else {
        right.add(products[i]);
      }
    }

    Widget buildColumn(List<_ProductCardData> column) {
      if (column.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < column.length; i++) ...[
            if (i > 0) const SizedBox(height: 24),
            _ProductCard(
              data: column[i],
              onImageTap: () => _openPropertyDetail(column[i]),
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: buildColumn(left)),
        const SizedBox(width: 12),
        Expanded(child: buildColumn(right)),
      ],
    );
  }

  Widget _buildFabColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showOnboardingFab) ...[
          _FabCircle(
            icon: Icons.school_outlined,
            onTap: _openOnboarding,
          ),
          const SizedBox(height: 12),
        ],
        _FabCircle(
          icon: Icons.add_rounded,
          onTap: () {
            _openAccountFeature(() async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddBelongingPage()),
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    const borderRadius = BorderRadius.all(Radius.circular(52));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SizedBox(
        height: 64,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(width: 2, color: _kBg),
                borderRadius: borderRadius,
                color: _kBg.withValues(alpha: 0.10),
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.white.withValues(alpha: 0.06)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GlassNavItem(
                    icon: _navIcons[0],
                    selected: _navIndex == 0,
                    onTap: () {
                      dismissAppKeyboard();
                      setState(() => _navIndex = 0);
                    },
                  ),
                  _GlassNavItem(
                    icon: _navIcons[1],
                    selected: _navIndex == 1,
                    onTap: () {
                      dismissAppKeyboard();
                      _openAccountFeature(() async {
                        setState(() => _navIndex = 1);
                        await Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeftWithFade,
                            duration: const Duration(milliseconds: 350),
                            reverseDuration: const Duration(milliseconds: 300),
                            child: const ListingsPage(),
                          ),
                        );
                        if (mounted) setState(() => _navIndex = 0);
                      });
                    },
                  ),
                  _GlassNavItem(
                    icon: _navIcons[2],
                    selected: _navIndex == 2,
                    onTap: () {
                      dismissAppKeyboard();
                      _openAccountFeature(() async {
                        setState(() => _navIndex = 2);
                        await Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.rightToLeftWithFade,
                            duration: const Duration(milliseconds: 350),
                            reverseDuration: const Duration(milliseconds: 300),
                            child:
                                const SwapBayPage(initialTab: SwapBayTab.sent),
                          ),
                        );
                        if (mounted) setState(() => _navIndex = 0);
                      });
                    },
                  ),
                  _GlassNavItem(
                    icon: _navIcons[3],
                    selected: _navIndex == 3,
                    onTap: () {
                      dismissAppKeyboard();
                      _openAccountFeature(() async {
                        setState(() => _navIndex = 3);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Profile()),
                        );
                        if (mounted) setState(() => _navIndex = 0);
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      containedInkWell: true,
      highlightShape: BoxShape.circle,
      child: Center(
        child: Iconify(
          icon,
          color: selected ? const Color(0xFFC3B649) : const Color(0xFF111111),
          size: 30,
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String label;
  final String iconAsset;

  const _CategoryItem(this.label, this.iconAsset);
}

class _ProductCardData {
  final String id;
  final String title;
  final String location;
  final String price;
  final String imageUrl;
  final double imageHeight;
  final Map<String, dynamic>? listingJson;

  const _ProductCardData({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
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
    final location = listingDisplayLocation(json);

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
      imageUrl: displayUrl ?? fallback,
      imageHeight: imageHeight,
      listingJson: json,
    );
  }
}

/// Figma "Location Search" (node 159:602) — text field with search action on the right.
class _LocationSearchBar extends StatelessWidget {
  const _LocationSearchBar({
    required this.controller,
    required this.focusNode,
    required this.onSearch,
    required this.textStyle,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;
  final TextStyle Function({double size, FontWeight weight, Color color})
  textStyle;

  static const double _height = 62;
  static const double _searchIconSize = 20;
  static const double _textSize = 16;
  static const double _hintSize = 13;
  static const double _clusterGap = 23;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: _kSearchBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              style: textStyle(
                size: _textSize,
                weight: FontWeight.w500,
                color: _kInk,
              ),
              textAlign: TextAlign.left,
              textInputAction: TextInputAction.search,
              onTapOutside: (_) => dismissAppKeyboard(),
              onSubmitted: (_) {
                dismissAppKeyboard();
                onSearch();
              },
              decoration: InputDecoration(
                hintText: 'find swap item',
                hintStyle: textStyle(
                  size: _hintSize,
                  weight: FontWeight.w400,
                  color: _kInk.withValues(alpha: 0.5),
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
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  final String icon;
  final bool showBadge;

  const _HeaderCircleButton({
    required this.icon,
    this.showBadge = false,
  });

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
            child: Center(
              child: Iconify(
                icon,
                size: 20,
                color: _kInk,
              ),
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
  final String iconAsset;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.label,
    required this.iconAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              iconAsset,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.style(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _kInk,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _ProductCardData data;
  final VoidCallback onImageTap;

  const _ProductCard({required this.data, required this.onImageTap});

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
        Text(
          data.price,
          style: AppTypography.style(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kHeartBg,
          ),
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
