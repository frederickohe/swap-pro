import 'package:swappro/barrel.dart';

/// Figma "Dash Listings" frame (node 162:1759).
class DashListingsPage extends StatefulWidget {
  const DashListingsPage({super.key});

  @override
  State<DashListingsPage> createState() => _DashListingsPageState();
}

class _DashListingsPageState extends State<DashListingsPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _searchBorder = Color(0xFFECECF3);
  static const Color _menuBorder = Color(0xFFDFDFDF);
  static const Color _backBg = Color(0xFFF5F4F8);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _divider = Color(0xFFF6F6F6);
  static const Color _viewBtn = Color(0xFF111111);

  static const double _thumbW = 255;
  static const double _thumbH = 217;

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<_DashListing> _allListings = [];
  String? _profilePictureUrl;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
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

      setState(() {
        _profilePictureUrl = photo.trim().isEmpty ? null : photo.trim();
        _allListings = listings.map(_DashListing.fromJson).toList();
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

  void _applySearch() {
    FocusScope.of(context).unfocus();
    setState(() => _query = _searchController.text.trim());
  }

  List<_DashListing> get _filteredListings {
    if (_query.isEmpty) return _allListings;
    final q = _query.toLowerCase();
    return _allListings
        .where(
          (item) =>
              item.title.toLowerCase().contains(q) ||
              item.category.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<void> _openDetail(_DashListing listing) async {
    if (listing.listingJson != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          duration: const Duration(milliseconds: 350),
          reverseDuration: const Duration(milliseconds: 300),
          child: PropertyDetailPage(
            data: PropertyDetailData.fromListing(listing.listingJson!),
          ),
        ),
      );
      return;
    }
    if (listing.id.isEmpty) return;
    try {
      final data = await context.read<ApiService>().getListing(listing.id);
      if (!mounted) return;
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.rightToLeftWithFade,
          duration: const Duration(milliseconds: 350),
          reverseDuration: const Duration(milliseconds: 300),
          child: PropertyDetailPage(
            data: PropertyDetailData.fromListing(data),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(e.toString());
    }
  }

  TextStyle _text({
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
    final filtered = _filteredListings;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 8, 20, 0),
                  child: _buildTopBar(context),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _error!,
                      style: _text(size: 12, color: Colors.red.shade700),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: _buildSearchRow(context),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: SwapproLoadingIndicator())
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadListings,
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  32,
                                  20,
                                  100 + bottomInset,
                                ),
                                itemCount: filtered.length,
                                separatorBuilder: (context, index) =>
                                    const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 27),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: _divider,
                                  ),
                                ),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return _ListingRow(
                                    data: item,
                                    onView: () => _openDetail(item),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
            Positioned(
              right: 38,
              bottom: 76 + bottomInset,
              child: _buildAddListingFab(context),
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
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 72),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Listed Properties',
                style: _text(
                  size: 22,
                  weight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: ClipOval(
              child: SizedBox(
                width: 65,
                height: 65,
                child: _profilePictureUrl != null
                    ? Image.network(
                        _profilePictureUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _avatarPlaceholder(),
                      )
                    : _avatarPlaceholder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: _backBg,
      child: const Icon(Icons.person, color: _subtitle, size: 32),
    );
  }

  Widget _buildSearchRow(BuildContext context) {
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
              style: _text(size: 14, weight: FontWeight.w500),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _applySearch(),
              decoration: InputDecoration(
                hintText: 'Search ...',
                hintStyle: _text(
                  size: 12,
                  weight: FontWeight.w500,
                  color: _ink.withValues(alpha: 0.5),
                ),
                suffixIcon: GestureDetector(
                  onTap: _applySearch,
                  child: const Icon(Icons.search, size: 18, color: _ink),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          _query.isEmpty
              ? 'No listings yet.\nTap + to add your first item.'
              : 'No listings match "$_query"',
          textAlign: TextAlign.center,
          style: _text(size: 16, color: _subtitle),
        ),
      ),
    );
  }

  Widget _buildAddListingFab(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeftWithFade,
            duration: const Duration(milliseconds: 350),
            reverseDuration: const Duration(milliseconds: 300),
            child: const AddBelongingPage(),
          ),
        ).then((_) {
          if (mounted) _loadListings();
        });
      },
      child: Container(
        width: 70,
        height: 60,
        decoration: const BoxDecoration(
          color: _viewBtn,
          borderRadius: BorderRadius.all(Radius.circular(45)),
        ),
        child: const Icon(
          Icons.add_circle_outline,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

class _DashListing {
  final String id;
  final String title;
  final String category;
  final String price;
  final String? imageUrl;
  final Map<String, dynamic>? listingJson;

  const _DashListing({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    this.imageUrl,
    this.listingJson,
  });

  factory _DashListing.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().trim();
    final category = (json['category'] ?? '').toString().trim();
    final condition = (json['condition'] ?? '').toString().trim();
    final subtitle = category.isNotEmpty
        ? category
        : (condition.isNotEmpty ? condition : 'Listing');

    final value = json['estimated_value'];
    final price = value is num
        ? 'GH₵ ${value.toStringAsFixed(2)}'
        : (value?.toString().trim().isNotEmpty == true ? 'GH₵ $value' : '—');

    return _DashListing(
      id: (json['id'] ?? '').toString(),
      title: title.isEmpty ? 'Untitled listing' : title,
      category: subtitle,
      price: price,
      imageUrl: listingDisplayImageUrl(json),
      listingJson: json,
    );
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({required this.data, required this.onView});

  final _DashListing data;
  final VoidCallback onView;

  static const Color _titleInk = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _priceInk = Color(0xFF292526);
  static const Color _viewBtn = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: _buildThumb(),
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
                      data.category,
                      style: AppTypography.style(
                        fontSize: 11,
                        color: _subtitle,
                      ),
                    ),
                    const SizedBox(height: 16),
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
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const _MoreMenuIcon(),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: onView,
                    child: Container(
                      width: 45,
                      height: 27,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _viewBtn,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'View',
                        style: AppTypography.style(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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

  Widget _buildThumb() {
    if (data.imageUrl != null) {
      return Image.network(
        data.imageUrl!,
        width: _DashListingsPageState._thumbW,
        height: _DashListingsPageState._thumbH,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      width: _DashListingsPageState._thumbW,
      height: _DashListingsPageState._thumbH,
      color: const Color(0xFFE8E8E8),
      child: const Icon(Icons.image_outlined, color: _subtitle),
    );
  }
}

class _MoreMenuIcon extends StatelessWidget {
  const _MoreMenuIcon();

  static const Color _dot = Color(0xFF292526);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        3,
        (i) => Padding(
          padding: EdgeInsets.only(left: i > 0 ? 2 : 0),
          child: Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: _dot,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
