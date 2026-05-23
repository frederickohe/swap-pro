import 'dart:math' as math;

import 'package:swappro/barrel.dart';

/// Brand loading animation: two circles orbiting a shared center.
class SwapproLoadingIndicator extends StatefulWidget {
  const SwapproLoadingIndicator({super.key, this.size = 40});

  final double size;

  static const Color _deepPurple = Color(0xFF7F03B9);
  static const Color _lightPurple = Color(0xFFA92FE2);

  @override
  State<SwapproLoadingIndicator> createState() =>
      _SwapproLoadingIndicatorState();
}

class _SwapproLoadingIndicatorState extends State<SwapproLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotDiameter = widget.size * 0.38;
    final orbitRadius = widget.size * 0.22;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * math.pi,
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: Offset(orbitRadius, 0),
              child: _dot(dotDiameter, SwapproLoadingIndicator._deepPurple),
            ),
            Transform.translate(
              offset: Offset(-orbitRadius, 0),
              child: _dot(dotDiameter, SwapproLoadingIndicator._lightPurple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
