import 'package:swappro/barrel.dart';

class SplashPge extends StatelessWidget {
  const SplashPge({super.key});

  static const Color _splashBackground = Color(0xFFC3B649);
  static const Color _textColor = Color(0xFF000000);
  static const Color _homeIndicatorColor = Color(0xFF1B1E28);

  static const double _figmaW = 430;
  static const double _figmaH = 932;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: _splashBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;
            final wScale = w / _figmaW;
            final hScale = h / _figmaH;

            final blockWidth = 225 * wScale;
            final logoWidth = 68 * wScale;
            final logoHeight = 64 * hScale;
            final logoRadius = 20 * wScale;
            final imageTextGap = 10 * hScale;
            final titleSubtitleGap = 19 * hScale;
            final titleFontSize = 38 * wScale;
            final subtitleFontSize = 12 * wScale;
            final homeIndicatorWidth = 134 * wScale;
            final homeIndicatorHeight = 5 * hScale;
            final homeIndicatorBottom = (34 - 21 - 5) * hScale;

            return Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment(0, ((253 + 222) / _figmaH) * 2 - 1),
                    child: SizedBox(
                      width: blockWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(logoRadius),
                            child: Image.asset(
                              'assets/icons/logo.png',
                              width: logoWidth,
                              height: logoHeight,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: imageTextGap),
                          Text(
                            'Swap Pro',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.righteous(
                              fontSize: titleFontSize,
                              color: _textColor,
                              height: 62 / 48,
                            ),
                          ),
                          SizedBox(height: titleSubtitleGap),
                          Text(
                            'Swap with and for anything',
                            textAlign: TextAlign.center,
                            style: AppTypography.style(
                              fontSize: subtitleFontSize,
                              fontWeight: FontWeight.w400,
                              color: _textColor,
                              height: 21 / 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: homeIndicatorBottom),
                  child: Center(
                    child: Container(
                      width: homeIndicatorWidth,
                      height: homeIndicatorHeight,
                      decoration: BoxDecoration(
                        color: _homeIndicatorColor,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
    );
  }
}
