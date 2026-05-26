import 'package:swappro/barrel.dart';

/// Listed properties hub — Figma "Listings" frame (node 162:622).
/// Shows the signed-in user's listings with search and quick actions.
class ListingsPage extends StatefulWidget {
  const ListingsPage({super.key});

  @override
  State<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends State<ListingsPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBtnBg = Color(0xFFF5F6F8);
  static const Color _searchBorder = Color(0xFFECECF3);
  static const Color _menuBorder = Color(0xFFDFDFDF);
  static const Color _divider = Color(0xFFF6F6F6);

  static const double _figmaW = 428;

  final TextEditingController _searchController = TextEditingController();

  List<_ListingRow> _allListings = [];
  bool _loading = true;
  String? _error;
  String? _profilePictureUrl;

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
      final api = context.read<ApiService>();
      final user = await api.getUserProfile();
      final photo =
          (user['profile_picture_url'] ?? user['avatar_url'] ?? '').toString();
      final listings = await api.getMyListings();
      if (!mounted) return;

      final rows = listings.map(_ListingRow.fromListing).where((r) {
        return r.title.trim().isNotEmpty;
      }).toList();

      setState(() {
        _profilePictureUrl = photo.trim().isEmpty ? null : photo.trim();
        _allListings = rows;
      });
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
        _allListings = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openListingDetail(_ListingRow item) async {
    if (item.listingJson != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailPage(
            data: PropertyDetailData.fromListing(item.listingJson!),
          ),
        ),
      );
      return;
    }
    final id = item.listingId;
    if (id == null || id.isEmpty) return;
    try {
      final listing = await context.read<ApiService>().getListing(id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PropertyDetailPage(
            data: PropertyDetailData.fromListing(listing),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(e.toString());
    }
  }

  List<_ListingRow> get _visibleListings {
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

  @override
  Widget build(BuildContext context) {
    final wScale = MediaQuery.sizeOf(context).width / _figmaW;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(wScale),
                if (_error != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20 * wScale),
                    child: Text(
                      _error!,
                      style: AppTypography.style(
                        color: Colors.red.shade700,
                        fontSize: 12 * wScale,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20 * wScale, 24 * wScale, 20 * wScale, 0),
                  child: _buildSearchHeader(wScale),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: SwapproLoadingIndicator())
                      : RefreshIndicator(
                          onRefresh: _loadListings,
                          child: _buildList(wScale),
                        ),
                ),
              ],
            ),
            Positioned(
              right: 38 * wScale,
              bottom: 24,
              child: _buildFabColumn(wScale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(double wScale) {
    return Padding(
      padding: EdgeInsets.fromLTRB(15 * wScale, 8 * wScale, 15 * wScale, 0),
      child: SizedBox(
        height: 65 * wScale,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 50 * wScale,
                  height: 50 * wScale,
                  decoration: const BoxDecoration(
                    color: _backBtnBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 18 * wScale,
                    color: _gold,
                  ),
                ),
              ),
            ),
            Text(
              'Listed Properties',
              style: AppTypography.style(
                fontSize: 20 * wScale,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _buildProfileAvatar(wScale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(double wScale) {
    final size = 65 * wScale;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: _profilePictureUrl != null
            ? Image.network(
                _profilePictureUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, e, s) => _avatarPlaceholder(size),
              )
            : _avatarPlaceholder(size),
      ),
    );
  }

  Widget _avatarPlaceholder(double size) {
    return Container(
      color: _backBtnBg,
      child: Icon(Icons.person, size: size * 0.45, color: _gold),
    );
  }

  Widget _buildSearchHeader(double wScale) {
    return Row(
      children: [
        Expanded(child: _buildSearchField(wScale)),
        SizedBox(width: 30 * wScale),
        _buildMenuButton(wScale),
      ],
    );
  }

  Widget _buildSearchField(double wScale) {
    return Container(
      height: 50 * wScale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25 * wScale),
        border: Border.all(color: _searchBorder),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16 * wScale),
      alignment: Alignment.center,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: AppTypography.style(
                fontSize: 14 * wScale,
                fontWeight: FontWeight.w400,
                color: _ink,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search ...',
                hintStyle: AppTypography.style(
                  fontSize: 14 * wScale,
                  color: _ink,
                ),
              ),
            ),
          ),
          Icon(Icons.search, size: 18 * wScale, color: _ink),
        ],
      ),
    );
  }

  Widget _buildMenuButton(double wScale) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => context.showAppSnackBar('Menu coming soon'),
        child: Container(
          width: 40 * wScale,
          height: 40 * wScale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _menuBorder),
          ),
          child: Icon(Icons.menu, size: 22 * wScale, color: _price),
        ),
      ),
    );
  }

  Widget _buildList(double wScale) {
    final items = _visibleListings;
    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20 * wScale, 32 * wScale, 20 * wScale, 120),
        children: [
          Text(
            _allListings.isEmpty
                ? 'You have no listings yet.\nTap + to add your first item.'
                : 'No listings match your search.',
            textAlign: TextAlign.center,
            style: AppTypography.style(
              fontSize: 14 * wScale,
              color: _subtitle,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20 * wScale, 32 * wScale, 20 * wScale, 160),
      itemCount: items.length,
      separatorBuilder: (_, i) => Padding(
        padding: EdgeInsets.symmetric(vertical: 27 * wScale),
        child: Divider(color: _divider, height: 1, thickness: 1),
      ),
      itemBuilder: (context, index) {
        return _ListingListTile(
          item: items[index],
          wScale: wScale,
          onView: () => _openListingDetail(items[index]),
          onMore: () => _showListingActions(items[index]),
        );
      },
    );
  }

  void _showListingActions(_ListingRow item) {
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
                title: const Text('Edit listing'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.showAppSnackBar('Edit coming soon');
                },
              ),
              ListTile(
                title: const Text('Remove listing'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.showAppSnackBar('Remove coming soon');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFabColumn(double wScale) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FabCircle(
          size: 70 * wScale,
          height: 60 * wScale,
          icon: Icons.tune,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchFiltersPage()),
            );
          },
        ),
        SizedBox(height: 15 * wScale),
        _FabCircle(
          size: 70 * wScale,
          height: 60 * wScale,
          icon: Icons.add_circle_outline,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddBelongingPage()),
            ).then((_) {
              if (mounted) _loadListings();
            });
          },
        ),
      ],
    );
  }
}

class _ListingRow {
  const _ListingRow({
    required this.title,
    required this.subtitle,
    required this.price,
    this.imageUrl,
    this.listingId,
    this.listingJson,
  });

  final String title;
  final String subtitle;
  final String price;
  final String? imageUrl;
  final String? listingId;
  final Map<String, dynamic>? listingJson;

  factory _ListingRow.fromListing(Map<String, dynamic> listing) {
    final title = (listing['title'] ?? '').toString().trim();
    final category = (listing['category'] ?? '').toString().trim();
    final condition = (listing['condition'] ?? '').toString().trim();
    final status = (listing['status'] ?? '').toString().trim();
    var subtitle = category.isNotEmpty
        ? category
        : (condition.isNotEmpty ? condition : 'Listing');
    if (status.isNotEmpty && status != 'ACTIVE') {
      subtitle = '$subtitle · $status';
    }

    final priceStr = _formatPrice(listing['estimated_value']);

    final imageUrl = listingDisplayImageUrl(listing);

    return _ListingRow(
      title: title.isEmpty ? 'Untitled listing' : title,
      subtitle: subtitle,
      price: priceStr,
      imageUrl: imageUrl,
      listingId: listing['id']?.toString(),
      listingJson: listing,
    );
  }

  static String _formatPrice(dynamic value) {
    if (value == null) return '—';
    if (value is num) {
      return 'GH₵ ${value.toStringAsFixed(2)}';
    }
    final s = value.toString().trim();
    if (s.isEmpty) return '—';
    return s.startsWith('GH') ? s : 'GH₵ $s';
  }
}

class _ListingListTile extends StatelessWidget {
  const _ListingListTile({
    required this.item,
    required this.wScale,
    required this.onView,
    required this.onMore,
  });

  final _ListingRow item;
  final double wScale;
  final VoidCallback onView;
  final VoidCallback onMore;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);
  static const Color _dark = Color(0xFF111111);
  static const double _thumbW = 255;
  static const double _thumbH = 217;

  @override
  Widget build(BuildContext context) {
    final thumbW = _thumbW * wScale;
    final thumbH = _thumbH * wScale;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5 * wScale),
          child: _buildThumb(thumbW, thumbH),
        ),
        SizedBox(width: 15 * wScale),
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
                      style: AppTypography.style(
                        fontSize: 14 * wScale,
                        fontWeight: FontWeight.w500,
                        color: _inkTitle,
                      ),
                    ),
                    SizedBox(height: 4 * wScale),
                    Text(
                      item.subtitle,
                      style: AppTypography.style(
                        fontSize: 11 * wScale,
                        fontWeight: FontWeight.w400,
                        color: _subtitle,
                      ),
                    ),
                    SizedBox(height: 16 * wScale),
                    Text(
                      item.price,
                      style: AppTypography.style(
                        fontSize: 14 * wScale,
                        fontWeight: FontWeight.w500,
                        color: _price,
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
                    child: Padding(
                      padding: EdgeInsets.only(left: 8 * wScale),
                      child: Icon(
                        Icons.more_horiz,
                        size: 24 * wScale,
                        color: _price,
                      ),
                    ),
                  ),
                  SizedBox(height: 20 * wScale),
                  GestureDetector(
                    onTap: onView,
                    child: Container(
                      width: 45 * wScale,
                      height: 27 * wScale,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _dark,
                        borderRadius: BorderRadius.circular(10 * wScale),
                      ),
                      child: Text(
                        'View',
                        style: AppTypography.style(
                          fontSize: 12 * wScale,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
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
    );
  }

  Widget _buildThumb(double thumbW, double thumbH) {
    if (item.imageUrl != null) {
      return Image.network(
        item.imageUrl!,
        width: thumbW,
        height: thumbH,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => _placeholder(thumbW, thumbH),
      );
    }
    return _placeholder(thumbW, thumbH);
  }

  Widget _placeholder(double thumbW, double thumbH) {
    return Container(
      width: thumbW,
      height: thumbH,
      color: const Color(0xFFF5F5F8),
      child: Icon(
        Icons.image_outlined,
        color: _dark.withValues(alpha: 0.3),
      ),
    );
  }
}

class _FabCircle extends StatelessWidget {
  const _FabCircle({
    required this.size,
    required this.height,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final double height;
  final IconData icon;
  final VoidCallback onTap;

  static const Color _dark = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _dark,
      borderRadius: BorderRadius.circular(45),
      child: InkWell(
        borderRadius: BorderRadius.circular(45),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: height,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
