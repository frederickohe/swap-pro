import 'package:swappro/barrel.dart';

class SplashPge extends StatelessWidget {
  const SplashPge({super.key});

  static const double _lottieSize = 220;

  @override
  Widget build(BuildContext context) {
    return const SwapLottieLoadingPage(size: _lottieSize);
  }
}
