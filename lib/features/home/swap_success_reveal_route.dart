import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swappro/features/home/property_swap_complete.dart';

/// Pushes the swap success screen with a green circle growing from the bottom-right.
class SwapSuccessRevealRoute extends PageRouteBuilder<void> {
  SwapSuccessRevealRoute()
      : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const PropertySwapCompletePage(delayEntrance: true),
          transitionDuration: const Duration(milliseconds: 1800),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _SwapSuccessRevealTransition(
              animation: animation,
              child: child,
            );
          },
        );
}

class _SwapSuccessRevealTransition extends StatelessWidget {
  const _SwapSuccessRevealTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  static const Color _green = Color(0xFF1A8118);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final reveal = Curves.easeOutCubic.transform(animation.value);
        final contentOpacity =
            Curves.easeOut.transform(((animation.value - 0.55) / 0.45).clamp(0.0, 1.0));

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white),
            CustomPaint(
              painter: _BottomRightCirclePainter(
                progress: reveal,
                color: _green,
              ),
              child: const SizedBox.expand(),
            ),
            Opacity(opacity: contentOpacity, child: child),
          ],
        );
      },
    );
  }
}

class _BottomRightCirclePainter extends CustomPainter {
  _BottomRightCirclePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width, size.height);
    final maxRadius = math.sqrt(
      size.width * size.width + size.height * size.height,
    );
    final radius = maxRadius * progress;

    canvas.drawCircle(center, radius, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BottomRightCirclePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
