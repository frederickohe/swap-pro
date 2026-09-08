import 'package:swappro/barrel.dart';
import 'package:swappro/common_design/widgets/success_reveal_route.dart';
import 'package:swappro/features/home/listing_location.dart';

/// User account hub — matches Figma "User Account" frame (node 162:829).
class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  static const Color _dark = Color(0xFF111111);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBtnBg = Color(0xFFF5F6F8);
  static const Color _verifyBg = Color(0xFF73193A);
  static const Color _divider = Color(0xFFF6F6F6);

  static const double _figmaW = 430;
  static const double _figmaH = 1177;

  String _displayName = 'User';
  String _email = '';
  String _location = '';
  String? _profilePictureUrl;
  bool _isVerified = false;
  bool _loading = true;
  bool _deletingAccount = false;

  List<_ListingItem> _previewListings = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
    });
    try {
      final api = context.read<ApiService>();
      final user = await api.getUserProfile();
      final listings = await api.getMyListings();
      if (!mounted) return;

      final name = (user['fullname'] ?? user['name'] ?? 'User').toString();
      final email = (user['email'] ?? '').toString();
      final location = (user['location'] ?? user['address'] ?? '').toString();
      final photo = (user['profile_picture_url'] ?? '').toString();
      final ghanaCard = (user['ghana_card'] ?? '').toString();

      final preview = listings.take(2).map(_ListingItem.fromListing).toList();

      setState(() {
        _displayName = name.trim().isEmpty ? 'User' : name.trim();
        _email = email;
        _location = location.trim().isEmpty ? 'Add location' : location.trim();
        _profilePictureUrl = photo.trim().isEmpty ? null : photo.trim();
        _isVerified = ghanaCard.trim().isNotEmpty;
        _previewListings = preview;
      });
    } catch (e) {
      if (!mounted) return;
      await ApiErrorHandler.handle(
        context,
        e,
        onRetry: _loadProfile,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openListingDetail(_ListingItem item) async {
    if (item.listingJson != null) {
      await prefetchListingLocations([item.listingJson!]);
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
      await prefetchListingLocations([listing]);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PropertyDetailPage(data: PropertyDetailData.fromListing(listing)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(e.toString());
    }
  }

  void _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEdit()),
    );
    if (mounted) _loadProfile();
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Delete account?',
                  style: AppTypography.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This permanently deletes your SwapPro account, profile, listings, and personal data. You will not be able to sign in again. This cannot be undone.',
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 13.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await context.read<ApiService>().deleteAccount();
      if (!mounted) return;

      context.read<SuccessBloc>().add(
            const ShowSuccessEvent(
              message: 'Your account has been deleted.',
              nextScreen: 'home',
            ),
          );
      context.read<AuthBloc>().add(
            const LogoutEvent(
              message: 'Your account has been deleted.',
              source: 'delete_account',
              skipServer: true,
            ),
          );
      Navigator.of(context).pushAndRemoveUntil(
        SuccessRevealRoute(
          child: const Success(delayEntrance: true),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingAccount = false);
      if (ApiErrorHandler.isSessionExpired(e)) {
        context.read<AuthBloc>().add(const SessionExpiredEvent());
        return;
      }
      await ApiErrorHandler.handle(context, e);
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Log out?',
                  style: AppTypography.style(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can log back in at any time.',
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 13.5,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          context.read<AuthBloc>().add(LogoutEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wScale = size.width / _figmaW;
    final hScale = size.height / _figmaH;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          if (state.source == 'delete_account') return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeEntry()),
            (route) => false,
          );
        } else if (state is AuthError && state.source == 'logout') {
          context.showAppSnackBar(state.message);
        }
      },
      child: AppScaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: _loading
              ? const Center(child: SwapproLoadingIndicator())
              : Stack(
                  children: [
                    Column(
                      children: [
                        _buildTopBar(wScale, hScale),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadProfile,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.only(bottom: 24 * hScale),
                              child: Column(
                                children: [
                                  SizedBox(height: 50 * hScale),
                                  _buildAvatar(wScale),
                                  SizedBox(height: 25 * hScale),
                                  _buildProfileInfo(wScale, hScale),
                                  SizedBox(height: 32 * hScale),
                                  _buildAccountOptions(wScale, hScale),
                                  SizedBox(height: 22 * hScale),
                                  _buildListingsSection(wScale, hScale),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_deletingAccount)
                      const ColoredBox(
                        color: Color(0x66000000),
                        child: Center(child: SwapproLoadingIndicator()),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTopBar(double wScale, double hScale) {
    return AppScreenTopBar(
      title: 'Your Profile',
      scale: wScale,
      showAvatar: false,
      padding: EdgeInsets.fromLTRB(15 * wScale, 10 * hScale, 15 * wScale, 0),
    );
  }

  Widget _buildAvatar(double wScale) {
    final size = 96 * wScale;
    return Transform.rotate(
      angle: 0.23,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: _profilePictureUrl != null
              ? Image.network(
                  _profilePictureUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => _avatarPlaceholder(size),
                )
              : _avatarPlaceholder(size),
        ),
      ),
    );
  }

  Widget _avatarPlaceholder(double size) {
    return Container(
      color: _backBtnBg,
      child: Icon(Icons.person, size: size * 0.45, color: _gold),
    );
  }

  Widget _buildProfileInfo(double wScale, double hScale) {
    return Column(
      children: [
        Text(
          _displayName,
          textAlign: TextAlign.center,
          style: AppTypography.style(
            fontSize: 28 * wScale,
            fontWeight: FontWeight.w500,
            color: _dark,
            height: 42 / 28,
          ),
        ),
        SizedBox(height: 4 * hScale),
        Text(
          _email.isEmpty ? '—' : _email,
          textAlign: TextAlign.center,
          style: AppTypography.style(
            fontSize: 16 * wScale,
            fontWeight: FontWeight.w400,
            color: _dark,
            height: 24 / 16,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(double wScale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.location_on_outlined, size: 20 * wScale, color: _dark),
        SizedBox(width: 4 * wScale),
        Text(
          _location,
          style: AppTypography.style(
            fontSize: 14 * wScale,
            fontWeight: FontWeight.w400,
            color: _dark,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyBadge(double wScale) {
    return GestureDetector(
      onTap: _openEdit,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16 * wScale,
          vertical: 5 * wScale,
        ),
        decoration: BoxDecoration(
          color: _verifyBg,
          borderRadius: BorderRadius.circular(8 * wScale),
        ),
        child: Text(
          'Verify',
          style: AppTypography.style(
            fontSize: 12 * wScale,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountOptions(double wScale, double hScale) {
    final items = <_AccountMenuItem>[
      _AccountMenuItem(
        label: 'Edit Profile',
        icon: Icons.edit_outlined,
        onTap: _openEdit,
      ),
      _AccountMenuItem(
        label: 'Change Password',
        icon: Icons.lock_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecoverAccount()),
        ),
      ),
      _AccountMenuItem(
        label: '2 Factor Authentication',
        icon: Icons.security_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TwoFactorAuthPage()),
        ),
      ),
      _AccountMenuItem(
        label: 'Help & Support',
        icon: Icons.help_outline,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HelpPage()),
        ),
      ),
      _AccountMenuItem(
        label: 'Delete Account',
        icon: Icons.delete_outline,
        destructive: true,
        onTap: _handleDeleteAccount,
      ),
      _AccountMenuItem(
        label: 'Log Out',
        icon: Icons.logout,
        onTap: () => _handleLogout(context),
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 26 * wScale),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10 * wScale),
        ),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              _AccountOptionTile(item: items[i], wScale: wScale),
              if (i < items.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _divider,
                  indent: 16 * wScale,
                  endIndent: 16 * wScale,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListingsSection(double wScale, double hScale) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 21 * wScale),
      child: Column(
        children: [
          Text(
            'Your Listings',
            style: AppTypography.style(
              fontSize: 20 * wScale,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 24 * hScale),
          if (_previewListings.isEmpty)
            Text(
              'No listings yet.',
              style: AppTypography.style(
                fontSize: 14 * wScale,
                color: const Color(0xFF787676),
              ),
            )
          else
            _buildListingsPreview(wScale),
          SizedBox(height: 28 * hScale),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListingsPage()),
              ).then((_) {
                if (mounted) _loadProfile();
              });
            },
            child: Text(
              'See All',
              style: AppTypography.style(
                fontSize: 20 * wScale,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsPreview(double wScale) {
    final items = _previewListings;
    if (items.length == 1) {
      return _ProfileListingGridCard(
        item: items[0],
        wScale: wScale,
        imageHeight: 217 * wScale,
        onTap: () => _openListingDetail(items[0]),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ProfileListingGridCard(
            item: items[0],
            wScale: wScale,
            imageHeight: 217 * wScale,
            onTap: () => _openListingDetail(items[0]),
          ),
        ),
        SizedBox(width: 45 * wScale),
        Expanded(
          child: _ProfileListingGridCard(
            item: items[1],
            wScale: wScale,
            imageHeight: 251 * wScale,
            onTap: () => _openListingDetail(items[1]),
          ),
        ),
      ],
    );
  }
}

class _AccountMenuItem {
  const _AccountMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
}

class _AccountOptionTile extends StatelessWidget {
  const _AccountOptionTile({required this.item, required this.wScale});

  final _AccountMenuItem item;
  final double wScale;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _menuText = Color(0xFF1C1C28);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 14 * wScale),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20 * wScale,
              color: item.destructive ? Colors.red : _gold,
            ),
            SizedBox(width: 12 * wScale),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.style(
                  fontSize: 16 * wScale,
                  fontWeight: FontWeight.w400,
                  color: item.destructive ? Colors.red : _menuText,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 24 * wScale, color: _menuText),
          ],
        ),
      ),
    );
  }
}

class _ListingItem {
  const _ListingItem({
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

  factory _ListingItem.fromListing(Map<String, dynamic> json) {
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

    return _ListingItem(
      title: title.isEmpty ? 'Untitled listing' : title,
      subtitle: subtitle,
      price: price,
      imageUrl: listingDisplayImageUrl(json),
      listingId: json['id']?.toString(),
      listingJson: json,
    );
  }
}

/// Vertical listing card — matches [ListingsPage] grid cards.
class _ProfileListingGridCard extends StatelessWidget {
  const _ProfileListingGridCard({
    required this.item,
    required this.wScale,
    required this.imageHeight,
    required this.onTap,
  });

  final _ListingItem item;
  final double wScale;
  final double imageHeight;
  final VoidCallback onTap;

  static const Color _inkTitle = Color(0xFF121111);
  static const Color _subtitle = Color(0xFF787676);
  static const Color _price = Color(0xFF292526);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10 * wScale),
            child: SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: _buildImage(),
            ),
          ),
          SizedBox(height: 8 * wScale),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.style(
              fontSize: 14 * wScale,
              fontWeight: FontWeight.w600,
              color: _inkTitle,
            ),
          ),
          SizedBox(height: 4 * wScale),
          Text(
            item.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.style(
              fontSize: 12 * wScale,
              color: _subtitle,
            ),
          ),
          SizedBox(height: 8 * wScale),
          Text(
            item.price,
            style: AppTypography.style(
              fontSize: 12 * wScale,
              fontWeight: FontWeight.w600,
              color: _price,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (item.imageUrl != null) {
      return Image.network(
        item.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, e, s) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF5F5F8),
      child: Icon(
        Icons.image_outlined,
        color: _price.withValues(alpha: 0.3),
      ),
    );
  }
}
