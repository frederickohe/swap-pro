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

  /// Figma frame 194:129 — chips flow horizontally and wrap when full.
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
    'Fitness',
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

    return Scaffold(
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
                child: _FigmaCategoryGrid(
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

/// Figma frame 194:129 — chips hug label width, 8px gap, wrap to next line, 20px row gap.
class _FigmaCategoryGrid extends StatelessWidget {
  final List<String> labels;
  final double scale;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _FigmaCategoryGrid({
    required this.labels,
    required this.scale,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const Color _chipBg = Color(0xFF111111);
  static const Color _chipSelectedBorder = Color(0xFFC3B649);

  @override
  Widget build(BuildContext context) {
    final gap = 8 * scale;
    final rowGap = 20 * scale;

    return Wrap(
      spacing: gap,
      runSpacing: rowGap,
      alignment: WrapAlignment.start,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++)
          _CategoryChip(
            label: labels[i],
            scale: scale,
            selected: selectedIndex == i,
            onTap: () => onSelected(i),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final double scale;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.scale,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final height = 40 * scale;
    final radius = 20 * scale;
    final hPad = 23 * scale;
    final fontSize = 14 * scale;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: height,
        padding: EdgeInsets.symmetric(horizontal: hPad),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _FigmaCategoryGrid._chipBg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: selected
                ? _FigmaCategoryGrid._chipSelectedBorder
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: AppTypography.style(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 22 / 14,
          ),
        ),
      ),
    );
  }
}
