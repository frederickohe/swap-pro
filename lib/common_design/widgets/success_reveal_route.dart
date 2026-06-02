import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A route transition that reveals the next page by growing a colored circle
/// from the bottom-right corner, then fading the content in.
class SuccessRevealRoute extends PageRouteBuilder<void> {
  SuccessRevealRoute({
    required Widget child,
    Color revealColor = const Color(0xFF1A8118),
    Duration transitionDuration = const Duration(milliseconds: 1800),
    Duration reverseTransitionDuration = const Duration(milliseconds: 500),
  }) : super(
          pageBuilder: (_, __, ___) => child,
          transitionDuration: transitionDuration,
          reverseTransitionDuration: reverseTransitionDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _SuccessRevealTransition(
              animation: animation,
              child: child,
              color: revealColor,
            );
          },
        );
}

class _SuccessRevealTransition extends StatelessWidget {
  const _SuccessRevealTransition({
    required this.animation,
    required this.child,
    required this.color,
  });

  final Animation<double> animation;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final reveal = Curves.easeOutCubic.transform(animation.value);
        final contentOpacity = Curves.easeOut.transform(
          ((animation.value - 0.55) / 0.45).clamp(0.0, 1.0),
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white),
            CustomPaint(
              painter: _BottomRightCirclePainter(
                progress: reveal,
                color: color,
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

