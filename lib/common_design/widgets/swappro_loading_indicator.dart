import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand loading animation: circular dashed stroke with a fading trail.
class SwapproLoadingIndicator extends StatefulWidget {
  const SwapproLoadingIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.showLabel = false,
    this.labelColor,
  });

  final double size;
  final Color? color;
  final bool showLabel;
  final Color? labelColor;

  static const Color _strokeColor = Color(0xFF111111);
  static const Color _labelGold = Color(0xFFC8A23F);

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
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strokeColor = widget.color ?? SwapproLoadingIndicator._strokeColor;
    final strokeWidth = 2 * widget.size / 50;

    final spinner = SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _DashedFadeLoaderPainter(
              progress: _controller.value,
              color: strokeColor,
              strokeWidth: strokeWidth,
            ),
          );
        },
      ),
    );

    if (!widget.showLabel) return spinner;

    final labelColor =
        widget.labelColor ?? SwapproLoadingIndicator._labelGold;
    final labelSize = widget.size * 0.48;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        spinner,
        SizedBox(height: widget.size * 0.92),
        Text(
          'SwapPro',
          style: GoogleFonts.righteous(
            fontSize: labelSize,
            color: labelColor,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _DashedFadeLoaderPainter extends CustomPainter {
  _DashedFadeLoaderPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final double strokeWidth;

  static const int _dashCount = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const sweep = 2 * math.pi;
    final slot = sweep / _dashCount;
    final dashSweep = slot * 0.55;
    final rotation = progress * sweep;

    for (var i = 0; i < _dashCount; i++) {
      final fade = 1 - (i / _dashCount);
      paint.color = color.withValues(alpha: fade.clamp(0.12, 1.0));
      canvas.drawArc(
        rect,
        rotation + i * slot - math.pi / 2,
        dashSweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedFadeLoaderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
