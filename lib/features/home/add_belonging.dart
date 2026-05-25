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

  /// Row layout from Figma frame 194:129 (horizontal rows, stacked vertically).
  static const List<List<String>> _itemCategoryRows = [
    ['Electronics', 'Home & Kitchen', 'kids'],
    ['Books', 'Fashion', 'Sports', 'Tools'],
    ['Fitness', 'Beauty Products', 'Vehicles'],
    ['Vehicle Parts', 'Fitness', 'Personal Care'],
    ['Media', 'Video Games'],
  ];

  static const List<List<String>> _incomingCategoryRows = [
    ['House', 'Lands', 'Building'],
    ['Software'],
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
      final raw = (user['fullname'] ??
              user['name'] ??
              user['username'] ??
              '')
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

  String _labelAtIndex(List<List<String>> rows, int? index) {
    if (index == null) return '';
    var cursor = 0;
    for (final row in rows) {
      for (final label in row) {
        if (cursor == index) return label;
        cursor++;
      }
    }
    return '';
  }

  void _goToSpecLabelStep() {
    final itemCategory =
        _labelAtIndex(_itemCategoryRows, _selectedItemCategoryIndex);
    if (itemCategory.isEmpty) return;

    final incomingCategory = _labelAtIndex(
      _incomingCategoryRows,
      _selectedIncomingCategoryIndex,
    );

    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        child: AddBelongingSpecLabelPage(
          itemCategory: itemCategory,
          incomingCategory:
              incomingCategory.isEmpty ? null : incomingCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wScale = MediaQuery.sizeOf(context).width / _figmaW;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(15 * wScale, 8 * wScale, 15 * wScale, 0),
                child: _buildHeader(wScale),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(26 * wScale, 48 * wScale, 26 * wScale, 0),
                child: _buildGreeting(wScale),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(26 * wScale, 49 * wScale, 26 * wScale, 0),
                child: _buildSectionTitle('Select Category', wScale),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24 * wScale, 37 * wScale, 24 * wScale, 0),
                child: _FigmaCategoryGrid(
                  rows: _itemCategoryRows,
                  selectedIndex: _selectedItemCategoryIndex,
                  onSelected: (index) {
                    setState(() => _selectedItemCategoryIndex = index);
                  },
                ),
              ),
            ),
            if (_selectedItemCategoryIndex != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(26 * wScale, 32 * wScale, 26 * wScale, 0),
                  child: Center(
                    child: AppButton(
                      buttonText: 'Next',
                      onPressed: _goToSpecLabelStep,
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  26 * wScale,
                  _selectedItemCategoryIndex != null ? 32 * wScale : 66 * wScale,
                  26 * wScale,
                  0,
                ),
                child: _buildSectionTitle('Incoming Category', wScale),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24 * wScale,
                  22 * wScale,
                  24 * wScale,
                  32 + MediaQuery.paddingOf(context).bottom,
                ),
                child: _FigmaCategoryGrid(
                  rows: _incomingCategoryRows,
                  selectedIndex: _selectedIncomingCategoryIndex,
                  onSelected: (index) {
                    setState(() => _selectedIncomingCategoryIndex = index);
                  },
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
      'Hi $_firstName, Fill detail of your belonging',
      style: AppTypography.style(
        fontSize: 28 * wScale,
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

/// Figma chip grid: short pills per label, 8px horizontal gap, 20px between rows.
class _FigmaCategoryGrid extends StatelessWidget {
  final List<List<String>> rows;
  final int? selectedIndex;
  final ValueChanged<int> onSelected;

  const _FigmaCategoryGrid({
    required this.rows,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const Color _chipBg = Color(0xFF111111);
  static const Color _chipSelectedBorder = Color(0xFFC3B649);

  int _indexFor(int row, int col) {
    var index = 0;
    for (var r = 0; r < row; r++) {
      index += rows[r].length;
    }
    return index + col;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
          if (rowIndex > 0) const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var colIndex = 0; colIndex < rows[rowIndex].length; colIndex++) ...[
                if (colIndex > 0) const SizedBox(width: 8),
                _CategoryChip(
                  label: rows[rowIndex][colIndex],
                  selected: selectedIndex == _indexFor(rowIndex, colIndex),
                  onTap: () => onSelected(_indexFor(rowIndex, colIndex)),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 23),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _FigmaCategoryGrid._chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? _FigmaCategoryGrid._chipSelectedBorder
                : _FigmaCategoryGrid._chipBg,
            width: selected ? 2 : 0,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.style(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            height: 22 / 14,
          ),
        ),
      ),
    );
  }
}
