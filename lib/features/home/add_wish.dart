import 'package:swappro/barrel.dart';

/// Add wish screen (Figma "Add Wish", node 194:658).
class AddWishPage extends StatefulWidget {
  const AddWishPage({super.key});

  @override
  State<AddWishPage> createState() => _AddWishPageState();
}

class _AddWishPageState extends State<AddWishPage> {
  static const Color _ink = Color(0xFF111111);
  static const Color _gold = Color(0xFFC3B649);
  static const Color _fieldBg = Color(0xFFF5F4F8);
  static const double _figmaW = 428;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSave() {
    final wish = _controller.text.trim();
    if (wish.isEmpty) return;
    Navigator.of(context).pop(wish);
  }

  @override
  Widget build(BuildContext context) {
    final wScale = MediaQuery.sizeOf(context).width / _figmaW;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(36 * wScale, 8 * wScale, 36 * wScale, 0),
              child: _buildBackButton(wScale),
            ),
            SizedBox(height: 95 * wScale),
            Text(
              'Add New Wishlist',
              textAlign: TextAlign.center,
              style: AppTypography.style(
                fontSize: 22 * wScale,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                height: 29 / 22,
              ),
            ),
            SizedBox(height: 72 * wScale),
            Center(
              child: _buildWishField(wScale),
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                76 * wScale,
                0,
                76 * wScale,
                36 + bottomInset,
              ),
              child: _buildSaveButton(wScale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(double wScale) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 50 * wScale,
          height: 50 * wScale,
          decoration: const BoxDecoration(
            color: _fieldBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back_ios_new,
            size: 18 * wScale,
            color: _gold,
          ),
        ),
      ),
    );
  }

  Widget _buildWishField(double wScale) {
    return Container(
      width: 224 * wScale,
      height: 46 * wScale,
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(25 * wScale),
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 15 * wScale),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textAlign: TextAlign.center,
        style: AppTypography.style(
          fontSize: 16 * wScale,
          fontWeight: FontWeight.w500,
          color: _ink,
        ),
        decoration: InputDecoration(
          hintText: '...',
          hintStyle: AppTypography.style(
            fontSize: 16 * wScale,
            fontWeight: FontWeight.w500,
            color: _ink.withValues(alpha: 0.45),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onSubmitted: (_) => _onSave(),
      ),
    );
  }

  Widget _buildSaveButton(double wScale) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final enabled = _controller.text.trim().isNotEmpty;
        return GestureDetector(
          onTap: enabled ? _onSave : null,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.45,
            duration: const Duration(milliseconds: 150),
            child: Container(
              height: 62 * wScale,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(10 * wScale),
              ),
              child: Text(
                'Save',
                style: AppTypography.style(
                  fontSize: 18 * wScale,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
