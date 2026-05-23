import 'package:swappro/barrel.dart';

// Figma Dashboard palette
const _kBg = Color(0xFFFFFFFF);
const _kInk = Color(0xFF111111);
const _kInkSoft = Color(0xFF787676);
const _kSearchBorder = Color(0xFFECECF3);
const _kNotifBorder = Color(0xFFDFDFDF);
const _kBadge = Color(0xFFFD5F4A);
const _kChipBg = Color(0xFFF5F4F8);
const _kNavBg = Color(0xFF111111);
const _kNavActive = Color(0x80414141);
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

  static const _wishlistItems = [
    'Car spare parts',
    'Turbo Washing Machine',
    'Brush',
    'Eggs',
    'Kids Skating Boots K892',
  ];

  static const _featuredProducts = [
    _ProductCardData(
      title: '2 Bedroom Self C',
      location: 'Lapaz',
      price: '\$212.99',
      rating: 5.0,
      imageUrl:
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400&q=80',
      imageHeight: 217,
    ),
    _ProductCardData(
      title: 'BMW Forza 2020',
      location: 'North Kaneshie',
      price: '₵662.99',
      rating: 5.0,
      imageUrl:
          'https://images.unsplash.com/photo-1555215695-3004980ad54e?w=400&q=80',
      imageHeight: 251,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _unreadCountFuture ??= context.read<ApiService>().getUnreadNotificationCount();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _unreadCountFuture = context.read<ApiService>().getUnreadNotificationCount();
    });
  }

  TextStyle _textStyle({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _kInk,
  }) {
    return GoogleFonts.montserrat(
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
                    child: _buildWishlistHeader(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(21, 12, 21, 0),
                    child: _buildWishlistChips(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 120 + bottomInset),
                    child: _buildProductRow(),
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
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _kSearchBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 18, color: _kInk),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search ...',
              style: _textStyle(size: 14, color: _kInk.withValues(alpha: 0.9)),
            ),
          ),
          const Icon(Icons.search, size: 18, color: _kInk),
        ],
      ),
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
        return _CategoryTile(
          label: cat.label,
          icon: cat.icon,
          onTap: () {},
        );
      },
    );
  }

  Widget _buildWishlistHeader() {
    return Row(
      children: [
        Text(
          'Your Wishlist',
          style: _textStyle(size: 22, weight: FontWeight.w600),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {},
          child: Text(
            'Add New +',
            style: _textStyle(size: 16, weight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _wishlistItems
          .map((label) => _WishlistChip(label: label, onTap: () {}))
          .toList(),
    );
  }

  Widget _buildProductRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _featuredProducts.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _ProductCard(data: _featuredProducts[i])),
        ],
      ],
    );
  }

  Widget _buildFabColumn() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FabCircle(
          icon: Icons.tune,
          onTap: () {},
        ),
        const SizedBox(height: 15),
        _FabCircle(
          icon: Icons.add_circle_outline,
          onTap: () {},
        ),
      ],
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
              onTap: () => setState(() => _navIndex = 1),
            ),
            _NavItem(
              icon: Icons.swap_horiz,
              selected: _navIndex == 2,
              onTap: () => setState(() => _navIndex = 2),
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
  final String title;
  final String location;
  final String price;
  final double rating;
  final String imageUrl;
  final double imageHeight;

  const _ProductCardData({
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageUrl,
    required this.imageHeight,
  });
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
              child: Icon(
                Icons.notifications_none,
                size: 22,
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
            style: GoogleFonts.montserrat(
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

class _WishlistChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _WishlistChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _kChipBg,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _kInk,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final _ProductCardData data;

  const _ProductCard({required this.data});

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
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  data.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFE8E8E8),
                    child: const Icon(Icons.image_outlined, color: _kInkSoft),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: _kHeartBg,
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
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF121111),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.location,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: _kInkSoft,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              data.price,
              style: GoogleFonts.montserrat(
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
              style: GoogleFonts.montserrat(
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
        decoration: const BoxDecoration(
          color: _kNavBg,
          shape: BoxShape.circle,
        ),
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
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: selected ? _kNavActive : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}
