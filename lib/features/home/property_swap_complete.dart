import 'package:swappro/barrel.dart';

/// Swap flow — request sent success (Figma "Complete", node 1:524).
class PropertySwapCompletePage extends StatefulWidget {
  const PropertySwapCompletePage({super.key, this.delayEntrance = false});

  /// When true, content entrance waits until the route reveal animation finishes.
  final bool delayEntrance;

  @override
  State<PropertySwapCompletePage> createState() =>
      _PropertySwapCompletePageState();
}

class _PropertySwapCompletePageState extends State<PropertySwapCompletePage>
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

    if (widget.delayEntrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startEntranceWhenReady());
    } else {
      _entrance.forward();
    }
  }

  void _startEntranceWhenReady() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    final routeAnim = route?.animation;
    if (routeAnim == null) {
      _entrance.forward();
      return;
    }
    void onStatus(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        routeAnim.removeStatusListener(onStatus);
        if (mounted) _entrance.forward();
      }
    }

    routeAnim.addStatusListener(onStatus);
    if (routeAnim.isCompleted) {
      routeAnim.removeStatusListener(onStatus);
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      PageTransition(
        type: PageTransitionType.rightToLeftWithFade,
        duration: const Duration(milliseconds: 350),
        reverseDuration: const Duration(milliseconds: 300),
        child: const HomeEntry(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wScale = size.width / _figmaW;
    final hScale = size.height / _figmaH;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AppScaffold(
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
                child: UserAvatar(
                  size: SettingsScreenStyle.chromeButtonSize * wScale,
                  onLightBackground: true,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 168 * hScale,
              child: FadeTransition(
                opacity: _titleOpacity,
                child: Text(
                  'Swap Request Sent',
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
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                    child: Image.asset(
                      'assets/icons/success.png',
                      width: 200 * wScale,
                      height: 263 * wScale,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.check_circle_outline,
                        size: 120 * wScale,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
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
                        onTap: () => _goHome(context),
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
