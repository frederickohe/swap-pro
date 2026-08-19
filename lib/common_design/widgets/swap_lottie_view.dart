import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:swappro/common_design/widgets/app_scaffold.dart';

/// White-canvas Lottie of two houses swapping, used on auth and bootstrap screens.
class SwapLottieView extends StatelessWidget {
  const SwapLottieView({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.repeat = true,
  });

  static const assetPath = 'assets/img/swaplottie.json';

  final double? width;
  final double? height;
  final BoxFit fit;
  final bool repeat;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      frameRate: FrameRate.max,
    );
  }
}

/// Full-screen white bootstrap shell with centered Lottie animation.
class SwapLottieLoadingPage extends StatelessWidget {
  const SwapLottieLoadingPage({super.key, this.size = 220});

  final double size;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SwapLottieView(width: size, height: size),
      ),
    );
  }
}
