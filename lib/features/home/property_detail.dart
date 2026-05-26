import 'package:swappro/barrel.dart';

/// Property detail — Figma "Property 2" frame (node 1:368).
class PropertyDetailPage extends StatelessWidget {
  const PropertyDetailPage({super.key, required this.data});

  final PropertyDetailData data;

  static const Color _ink = Color(0xFF111111);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBg = Color(0xFFF5F4F8);
  static const Color _chipBg = Color(0xFFF5F4F8);

  TextStyle _text({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = _ink,
    double? height,
  }) {
    return AppTypography.style(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildBackButton(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(23, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGallery(),
                    const SizedBox(height: 38),
                    Text(
                      data.title,
                      style: _text(
                        size: 28,
                        weight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 38),
                    Text(
                      data.description,
                      style: _text(
                        size: 16,
                        color: Colors.black,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 38),
                    _buildOwnerRow(),
                    const SizedBox(height: 38),
                    _buildWishlistSection(),
                    const SizedBox(height: 38),
                    _buildPriceRow(),
                    const SizedBox(height: 38),
                    _buildMetadataGrid(),
                    SizedBox(height: 100 + bottomInset),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + bottomInset),
              child: _buildSwapButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Align(
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
    );
  }

  void _openImageViewer(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        duration: const Duration(milliseconds: 300),
        reverseDuration: const Duration(milliseconds: 250),
        child: PropertySwapImagePage(
          data: data,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: data.imageUrls.length,
        separatorBuilder: (context, index) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _openImageViewer(context, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 80,
                height: 100,
                child: Image.network(
                  data.imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFE8E8E8),
                    child: const Icon(Icons.image_outlined, color: _ink),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOwnerRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Owner :',
          style: _text(size: 18, weight: FontWeight.w500),
        ),
        const SizedBox(width: 19),
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFFE8E8E8),
                backgroundImage: data.ownerAvatarUrl != null
                    ? NetworkImage(data.ownerAvatarUrl!)
                    : null,
                child: data.ownerAvatarUrl == null
                    ? Text(
                        data.ownerName.isNotEmpty
                            ? data.ownerName[0].toUpperCase()
                            : '?',
                        style: _text(size: 18, weight: FontWeight.w600),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                data.ownerName,
                style: _text(size: 16, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWishlistSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Wishlist',
          style: _text(size: 18, weight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.wishlistItems
              .map((label) => _WishlistChip(label: label))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Price :',
            style: _text(size: 18, weight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          data.price,
          style: _text(
            size: 28,
            weight: FontWeight.w600,
            color: _gold,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetadataTile(
                icon: Icons.calendar_month_outlined,
                label: 'Date',
                value: data.date,
              ),
            ),
            const SizedBox(width: 55),
            Expanded(
              child: _MetadataTile(
                icon: Icons.category_outlined,
                label: 'Category',
                value: data.category,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetadataTile(
                icon: Icons.description_outlined,
                label: 'Receipts',
                value: data.receipts,
              ),
            ),
            const SizedBox(width: 55),
            Expanded(
              child: _MetadataTile(
                icon: Icons.info_outline,
                label: 'Status',
                value: data.status,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwapButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.rightToLeftWithFade,
            duration: const Duration(milliseconds: 350),
            reverseDuration: const Duration(milliseconds: 300),
            child: PropertySwapConfirmPage(data: data),
          ),
        );
      },
      child: Container(
        height: 69,
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text(
              'Swap This',
              style: _text(
                size: 18,
                weight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_backspace,
              color: Colors.white,
              size: 28,
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}

class PropertyDetailData {
  const PropertyDetailData({
    required this.title,
    required this.description,
    required this.imageUrls,
    required this.ownerName,
    this.ownerAvatarUrl,
    required this.wishlistItems,
    required this.price,
    required this.date,
    required this.category,
    required this.receipts,
    required this.status,
  });

  final String title;
  final String description;
  final List<String> imageUrls;
  final String ownerName;
  final String? ownerAvatarUrl;
  final List<String> wishlistItems;
  final String price;
  final String date;
  final String category;
  final String receipts;
  final String status;

  /// Build detail payload from `GET /api/v1/listings/{id}` (or search item).
  factory PropertyDetailData.fromListing(
    Map<String, dynamic> json, {
    String ownerName = 'Seller',
    String? ownerAvatarUrl,
  }) {
    final wishlistRaw = json['wishlist'];
    final wishlistItems = <String>[];
    if (wishlistRaw is List) {
      for (final item in wishlistRaw) {
        if (item is Map) {
          final label =
              (item['description'] ?? item['category'] ?? '').toString().trim();
          if (label.isNotEmpty) wishlistItems.add(label);
        } else {
          final label = item.toString().trim();
          if (label.isNotEmpty) wishlistItems.add(label);
        }
      }
    }

    final imageUrls = <String>[];
    final primary = (json['primary_image_url'] ?? '').toString().trim();
    if (primary.isNotEmpty) imageUrls.add(primary);
    final extras = json['image_urls'];
    if (extras is List) {
      for (final url in extras) {
        final s = url.toString().trim();
        if (s.isNotEmpty && !imageUrls.contains(s)) imageUrls.add(s);
      }
    }
    if (imageUrls.isEmpty) {
      imageUrls.add(
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=400&q=80',
      );
    }

    final value = json['estimated_value'];
    final price = value is num
        ? 'GH₵ ${value.toStringAsFixed(2)}'
        : (value?.toString().trim().isNotEmpty == true ? 'GH₵ $value' : '—');

    final createdAt = json['created_at']?.toString() ?? '';
    String date = '—';
    if (createdAt.length >= 10) {
      try {
        final dt = DateTime.parse(createdAt);
        date =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {
        date = createdAt.substring(0, 10);
      }
    }

    return PropertyDetailData(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrls: imageUrls,
      ownerName: ownerName,
      ownerAvatarUrl: ownerAvatarUrl,
      wishlistItems: wishlistItems,
      price: price,
      date: date,
      category: (json['category'] ?? '—').toString(),
      receipts: json['ownership_documents_available'] == true ? 'Yes' : 'No',
      status: (json['condition'] ?? json['status'] ?? '—').toString(),
    );
  }

  /// Demo detail payload aligned with Figma "Property 2" sample content.
  factory PropertyDetailData.demo({
    required String title,
    required String price,
    required String imageUrl,
    String? location,
  }) {
    final category = location ?? 'Building';
    return PropertyDetailData(
      title: title,
      description:
          'Nice $title for a cool swap deal.',
      imageUrls: [
        imageUrl,
        'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=400&q=80',
        'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=400&q=80',
        'https://images.unsplash.com/photo-1583121274602-3e2820c58988?w=400&q=80',
      ],
      ownerName: 'Jeff Anderson',
      ownerAvatarUrl:
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&q=80',
      wishlistItems: const [
        'Car spare parts',
        'Turbo Washing Machine',
        'Brush',
        'Eggs',
        'Kids Skating Boots K892',
      ],
      price: price.startsWith('₵') || price.startsWith('\$')
          ? price
          : 'GH₵ $price',
      date: '30/01/2025',
      category: category,
      receipts: 'Yes',
      status: 'Used',
    );
  }
}

class _WishlistChip extends StatelessWidget {
  const _WishlistChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: PropertyDetailPage._chipBg,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        label,
        style: AppTypography.style(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: PropertyDetailPage._ink,
        ),
      ),
    );
  }
}

class _MetadataTile extends StatelessWidget {
  const _MetadataTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: PropertyDetailPage._ink),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.style(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: PropertyDetailPage._ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: AppTypography.style(
                  fontSize: 14,
                  color: PropertyDetailPage._ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
