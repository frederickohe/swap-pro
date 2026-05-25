import 'package:swappro/barrel.dart';

/// Add belonging flow — success screen (Figma "Complete", node 194:623).
class AddBelongingCompletePage extends StatefulWidget {
  const AddBelongingCompletePage({super.key});

  @override
  State<AddBelongingCompletePage> createState() => _AddBelongingCompletePageState();
}

class _AddBelongingCompletePageState extends State<AddBelongingCompletePage>
    with SingleTickerProviderStateMixin {
  static const Color _greenBg = Color(0xFF1A8118);
  static const Color _ink = Color(0xFF111111);
  static const double _figmaW = 428;
  static const double _figmaH = 926;

  late final AnimationController _entrance;
  late final Animation<double> _headerOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _imageOpacity;
  late final Animation<double> _imageScale;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _headerOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _titleOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.15, 0.5, curve: Curves.easeOut),
    );
    _imageOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
    );
    _imageScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOutBack),
      ),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _buttonOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
    );

    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _goToListings(BuildContext context) {
    Navigator.of(context).pushReplacement(
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        child: const ListingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wScale = size.width / _figmaW;
    final hScale = size.height / _figmaH;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _greenBg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              left: 39 * wScale,
              top: 17 * hScale,
              child: FadeTransition(
                opacity: _headerOpacity,
                child: Text(
                  'Swapping',
                  style: AppTypography.style(
                    fontSize: 20 * wScale,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 29 / 20,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 25 * wScale,
              top: 0,
              child: FadeTransition(
                opacity: _headerOpacity,
                child: UserAvatar(size: 65 * wScale),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 168 * hScale,
              child: FadeTransition(
                opacity: _titleOpacity,
                child: Text(
                  'Belonging Added',
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 32 * wScale,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    height: 51 / 32,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 114 * wScale,
              top: 273 * hScale,
              child: FadeTransition(
                opacity: _imageOpacity,
                child: ScaleTransition(
                  scale: _imageScale,
                  child: Image.asset(
                    'assets/icons/success.png',
                    width: 200 * wScale,
                    height: 263 * wScale,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.celebration_outlined,
                      size: 120 * wScale,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 116 * hScale + bottomInset,
              child: FadeTransition(
                opacity: _buttonOpacity,
                child: SlideTransition(
                  position: _buttonSlide,
                  child: Center(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _goToListings(context),
                        borderRadius: BorderRadius.circular(10 * wScale),
                        child: Ink(
                          width: 277 * wScale,
                          height: 62 * wScale,
                          decoration: BoxDecoration(
                            color: _ink,
                            borderRadius: BorderRadius.circular(10 * wScale),
                          ),
                          child: Center(
                            child: Text(
                              'Proceed',
                              style: AppTypography.style(
                                fontSize: 18 * wScale,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                height: 24 / 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
