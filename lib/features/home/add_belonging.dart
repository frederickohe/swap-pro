import 'package:swappro/barrel.dart';

/// Add belonging flow — step 1 category pick (Figma "Add 01", node 191:716).
class AddBelongingPage extends StatefulWidget {
  const AddBelongingPage({super.key});

  @override
  State<AddBelongingPage> createState() => _AddBelongingPageState();
}

class _AddBelongingPageState extends State<AddBelongingPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _backBtnBg = Color(0xFFF5F4F8);

  static const double _figmaW = 428;
  static const double _figmaH = 932;

  /// Matches backend LISTING_ITEM_CATEGORIES / home category strip.
  static const List<String> _itemCategories = [
    'Electronics',
    'Home & Kitchen',
    'kids',
    'Books',
    'Fashion',
    'Sports',
    'Tools',
    'Fitness',
    'Beauty Products',
    'Vehicles',
    'Vehicle Parts',
    'Personal Care',
    'Media',
    'Video Games',
  ];

  static const List<String> _incomingCategories = [
    'House',
    'Lands',
    'Building',
    'Software',
  ];

  int? _selectedItemCategoryIndex;
  int? _selectedIncomingCategoryIndex;
  String _firstName = 'there';
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = await context.read<ApiService>().getUserProfile();
      if (!mounted) return;
      final raw = (user['fullname'] ?? user['name'] ?? user['username'] ?? '')
          .toString()
          .trim();
      final first = raw.isEmpty ? 'there' : raw.split(RegExp(r'\s+')).first;
      setState(() => _firstName = first);
    } catch (_) {
      // Keep fallback greeting.
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _labelAtIndex(List<String> labels, int? index) {
    if (index == null || index < 0 || index >= labels.length) return '';
    return labels[index];
  }

  void _goToSpecLabelStep() {
    final itemCategory = _labelAtIndex(
      _itemCategories,
      _selectedItemCategoryIndex,
    );
    if (itemCategory.isEmpty) return;

    final incomingCategory = _labelAtIndex(
      _incomingCategories,
      _selectedIncomingCategoryIndex,
    );

    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        child: AddBelongingSpecLabelPage(
          itemCategory: itemCategory,
          incomingCategory: incomingCategory.isEmpty ? null : incomingCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wScale = size.width / _figmaW;
    final hScale = size.height / _figmaH;
    final canContinue = _selectedItemCategoryIndex != null;

    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  15 * wScale,
                  8 * wScale,
                  15 * wScale,
                  0,
                ),
                child: _buildHeader(wScale),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  26 * wScale,
                  48 * wScale,
                  26 * wScale,
                  0,
                ),
                child: _buildGreeting(wScale),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  26 * wScale,
                  49 * wScale,
                  26 * wScale,
                  0,
                ),
                child: _buildSectionTitle('Select Category', wScale),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24 * wScale,
                  37 * wScale,
                  24 * wScale,
                  0,
                ),
                child: _ModernCategoryGrid(
                  labels: _itemCategories,
                  scale: wScale,
                  selectedIndex: _selectedItemCategoryIndex,
                  onSelected: (index) {
                    setState(() => _selectedItemCategoryIndex = index);
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  26 * wScale,
                  32 * wScale,
                  26 * wScale,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                child: Center(
                  child: AuthPrimaryButton(
                    label: 'Next',
                    onPressed: canContinue ? _goToSpecLabelStep : null,
                    width: 277 * wScale,
                    height: 62 * hScale,
                    radius: 10 * wScale,
                    fontSize: 16 * wScale,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double wScale) {
    return SizedBox(
      height: 50 * wScale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
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
            'Add Belonging',
            style: AppTypography.style(
              fontSize: 20 * wScale,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(double wScale) {
    if (_loadingProfile) {
      return SizedBox(
        height: 90 * wScale,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: _ink),
          ),
        ),
      );
    }

    return Text(
      'Hi $_firstName, Detail your belonging for us',
      style: AppTypography.style(
        fontSize: 24 * wScale,
        fontWeight: FontWeight.w500,
        color: Colors.black,
        height: 1.25,
      ),
    );
  }

  Widget _buildSectionTitle(String title, double wScale) {
    return Text(
      title,
      style: AppTypography.style(
        fontSize: 22 * wScale,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
    );
  }
}

class _ModernCategoryGrid extends StatelessWidget {
  final List<String> labels;
  final double scale;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _ModernCategoryGrid({
    required this.labels,
    required this.scale,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const Color _ink = Color(0xFF111111);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _cardBorder = Color(0xFFE6E8EF);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _cardBgSelected = Color(0xFF111111);
  static const Color _cardIconBg = Color(0xFFF5F4F8);

  @override
  Widget build(BuildContext context) {
    final gap = 12 * scale;
    final cardHeight = 72 * scale;
    final radius = 16 * scale;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final minTile = 170 * scale;
        final crossAxisCount = w >= (minTile * 3 + gap * 2)
            ? 3
            : (w >= (minTile * 2 + gap) ? 2 : 1);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: labels.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: cardHeight,
          ),
          itemBuilder: (context, i) {
            final selected = selectedIndex == i;
            return _CategoryCard(
              label: labels[i],
              selected: selected,
              radius: radius,
              onTap: () => onSelected(i),
              icon: _iconFor(labels[i]),
            );
          },
        );
      },
    );
  }

  IconData _iconFor(String label) {
    final s = label.toLowerCase();
    if (s.contains('elect')) return Icons.devices;
    if (s.contains('home') || s.contains('kitchen')) return Icons.chair_alt;
    if (s.contains('kid')) return Icons.child_care;
    if (s.contains('book')) return Icons.menu_book;
    if (s.contains('fashion')) return Icons.checkroom;
    if (s.contains('sport')) return Icons.sports_soccer;
    if (s.contains('tool')) return Icons.handyman;
    if (s.contains('fitness')) return Icons.fitness_center;
    if (s.contains('beauty')) return Icons.spa;
    if (s.contains('vehicle part')) return Icons.build_circle;
    if (s.contains('vehicle')) return Icons.directions_car;
    if (s.contains('personal care')) return Icons.self_improvement;
    if (s.contains('media')) return Icons.movie;
    if (s.contains('video game')) return Icons.sports_esports;
    return Icons.category;
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double radius;
  final IconData icon;

  const _CategoryCard({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.radius,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final padH = 14 / scale;
    final padV = 12 / scale;
    final iconSize = 22 / scale;

    final bg = selected ? _ModernCategoryGrid._cardBgSelected : _ModernCategoryGrid._cardBg;
    final borderColor = selected ? _ModernCategoryGrid._gold : _ModernCategoryGrid._cardBorder;
    final textColor = selected ? Colors.white : _ModernCategoryGrid._ink;
    final iconBg = selected ? Colors.white.withValues(alpha: 0.14) : _ModernCategoryGrid._cardIconBg;
    final iconColor = selected ? Colors.white : _ModernCategoryGrid._ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              children: [
                Container(
                  width: 40 / scale,
                  height: 40 / scale,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12 / scale),
                  ),
                  child: Icon(icon, size: iconSize, color: iconColor),
                ),
                SizedBox(width: 12 / scale),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(
                      fontSize: 14 / scale,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.15,
                    ),
                  ),
                ),
                if (selected) ...[
                  SizedBox(width: 10 / scale),
                  Container(
                    width: 26 / scale,
                    height: 26 / scale,
                    decoration: BoxDecoration(
                      color: _ModernCategoryGrid._gold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(
                      Icons.check,
                      size: 16 / scale,
                      color: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
