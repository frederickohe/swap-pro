import 'package:swappro/barrel.dart';

class Success extends StatefulWidget {
  const Success({super.key, this.delayEntrance = false});

  /// When true, entrance waits for the route reveal animation to finish.
  final bool delayEntrance;

  @override
  State<Success> createState() => _SuccessState();
}

class _SuccessState extends State<Success> with SingleTickerProviderStateMixin {
  static const Color _greenBg = Color(0xFF1A8118);
  static const Color _ink = Color(0xFF111111);
  static const double _figmaW = 428;
  static const double _figmaH = 926;

  late final AnimationController _entrance;
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

    _titleOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOut),
    );
    _imageOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.15, 0.6, curve: Curves.easeOut),
    );
    _imageScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _buttonSlide = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entrance,
            curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _buttonOpacity = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 0.9, curve: Curves.easeOut),
    );

    if (widget.delayEntrance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startEntranceWhenReady();
      });
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wScale = size.width / _figmaW;
    final hScale = size.height / _figmaH;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _greenBg,
      body: BlocListener<SuccessBloc, SuccessState>(
        listener: (context, state) {
          // Handle navigation when success state changes
          if (state is SuccessDisplaying) {
            // You can add navigation logic here if needed
          }
        },
        child: BlocBuilder<SuccessBloc, SuccessState>(
          builder: (context, state) {
            // Extract message and nextScreen based on state
            String displayMessage = 'Account creation was successful!';
            String? nextScreen;

            if (state is SuccessDisplaying) {
              displayMessage = state.message;
              nextScreen = state.nextScreen;
            }

            final ctaLabel = nextScreen == 'login'
                ? 'Proceed to Login'
                : 'Proceed';

            return SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 168 * hScale,
                    child: FadeTransition(
                      opacity: _titleOpacity,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 28 * wScale),
                        child: Text(
                          displayMessage,
                          textAlign: TextAlign.center,
                          style: AppTypography.style(
                            fontSize: 26 * wScale,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 273 * hScale,
                    child: FadeTransition(
                      opacity: _imageOpacity,
                      child: ScaleTransition(
                        scale: _imageScale,
                        child: Center(
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 120 * wScale,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
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
                              onTap: () {
                                context.read<SuccessBloc>().add(
                                  const ClearSuccessEvent(),
                                );

                                if (nextScreen == 'login') {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => const Signin(),
                                    ),
                                  );
                                  return;
                                }
                                if (nextScreen == 'home') {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    Home.routeFromWelcome(),
                                    (_) => false,
                                  );
                                  return;
                                }
                              },
                              borderRadius: BorderRadius.circular(10 * wScale),
                              child: Ink(
                                width: 277 * wScale,
                                height: 62 * wScale,
                                decoration: BoxDecoration(
                                  color: _ink,
                                  borderRadius: BorderRadius.circular(
                                    10 * wScale,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    ctaLabel,
                                    textAlign: TextAlign.center,
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
            );
          },
        ),
      ),
    );
  }
}
