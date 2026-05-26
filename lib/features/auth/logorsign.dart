import 'package:swappro/barrel.dart';

class LogorSign extends StatelessWidget {
  const LogorSign({super.key});

  static const Color _textBlack = Color(0xFF000000);

  static const double _figmaW = 430;
  static const double _figmaH = 932;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final h = size.height;
    final w = size.width;
    final wScale = w / _figmaW;
    final hScale = h / _figmaH;

    final logoWidth = 68 * wScale;
    final logoHeight = 64 * hScale;
    final logoTop = 218 * hScale;
    final panelHeight = 396 * hScale;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/img/splash.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 24 * hScale,
            right: 24 * wScale,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  PageTransition(
                    type: PageTransitionType.fade,
                    duration: const Duration(milliseconds: 400),
                    child: const AdminSignIn(),
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: Text(
                'Admin',
                style: AppTypography.style(
                  fontSize: 14 * wScale,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned(
            top: logoTop,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20 * wScale),
                child: Image.asset(
                  'assets/icons/logo.png',
                  width: logoWidth,
                  height: logoHeight,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: panelHeight,
            child: _BottomPanel(height: panelHeight, width: w),
          ),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.height, required this.width});

  final double height;
  final double width;

  static const Color _gold = Color(0xFFC3B649);
  static const Color _darkButton = Color(0xFF111111);

  static const double _figmaW = 430;
  static const double _figmaPanelH = 396;

  @override
  Widget build(BuildContext context) {
    final wScale = width / _figmaW;
    final hScale = height / _figmaPanelH;

    final titleTop = 31 * hScale;
    final signInTop = 111 * hScale;
    final createAccountTop = 210 * hScale;
    final signInWidth = 276 * wScale;
    final signInHeight = 60 * hScale;
    final createAccountWidth = 277 * wScale;
    final createAccountHeight = 62 * hScale;
    final buttonRadius = 10 * wScale;

    TextStyle titleStyle() => AppTypography.style(
      fontSize: 26 * wScale,
      fontWeight: FontWeight.w600,
      color: LogorSign._textBlack,
      height: 40 / 32,
    );

    TextStyle outlinedButtonStyle() => AppTypography.style(
      fontSize: 14 * wScale,
      fontWeight: FontWeight.w500,
      color: LogorSign._textBlack,
    );

    TextStyle filledButtonStyle() => AppTypography.style(
      fontSize: 14 * wScale,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );

    return ColoredBox(
      color: _gold.withValues(alpha: 0.7),
      child: Stack(
        children: [
          Positioned(
            top: titleTop,
            left: 0,
            right: 0,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: titleStyle(),
                children: [
                  TextSpan(
                    text: 'Ready to ',
                    style: titleStyle().copyWith(fontWeight: FontWeight.w300),
                  ),
                  TextSpan(
                    text: 'Swap?',
                    style: titleStyle().copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: signInTop,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: signInWidth,
                height: signInHeight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageTransition(
                        type: PageTransitionType.rightToLeftWithFade,
                        duration: const Duration(milliseconds: 1000),
                        reverseDuration: const Duration(milliseconds: 800),
                        child: const Signin(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LogorSign._textBlack,
                    side: const BorderSide(
                      color: LogorSign._textBlack,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonRadius),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  child: Text('Log in', style: outlinedButtonStyle()),
                ),
              ),
            ),
          ),
          Positioned(
            top: createAccountTop,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: createAccountWidth,
                height: createAccountHeight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageTransition(
                        type: PageTransitionType.rightToLeftWithFade,
                        duration: const Duration(milliseconds: 1000),
                        reverseDuration: const Duration(milliseconds: 600),
                        child: const Signup(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _darkButton,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(buttonRadius),
                    ),
                  ),
                  child: Text('Create Account', style: filledButtonStyle()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
