import 'package:swappro/barrel.dart';

class LogorSign extends StatelessWidget {
  const LogorSign({super.key});

  static const Color _textBlack = Color(0xFF000000);
  static const Color _darkButton = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final logoSize = (width * 0.18).clamp(64.0, 82.0);
            final lottieSize = (width * 0.5).clamp(180.0, 240.0);
            final buttonWidth = (width * 0.72).clamp(240.0, 320.0);

            TextStyle titleStyle() => AppTypography.style(
              fontSize: 26,
              fontWeight: FontWeight.w300,
              color: _textBlack,
              height: 40 / 32,
            );

            TextStyle outlinedButtonStyle() => AppTypography.style(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _textBlack,
            );

            TextStyle filledButtonStyle() => AppTypography.style(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icons/logo.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwapLottieView(
                      width: lottieSize,
                      height: lottieSize,
                    ),
                    const Spacer(),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: titleStyle(),
                        children: [
                          TextSpan(
                            text: 'Ready to ',
                            style: titleStyle().copyWith(
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          TextSpan(
                            text: 'Swap?',
                            style: titleStyle().copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: buttonWidth,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageTransition(
                              type: PageTransitionType.rightToLeftWithFade,
                              duration: const Duration(milliseconds: 1000),
                              reverseDuration:
                                  const Duration(milliseconds: 800),
                              child: const Signin(),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textBlack,
                          side: const BorderSide(color: _textBlack, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: Colors.white,
                        ),
                        child: Text('Log in', style: outlinedButtonStyle()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: buttonWidth,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageTransition(
                              type: PageTransitionType.rightToLeftWithFade,
                              duration: const Duration(milliseconds: 1000),
                              reverseDuration:
                                  const Duration(milliseconds: 600),
                              child: const Signup(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkButton,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Create Account',
                          style: filledButtonStyle(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
