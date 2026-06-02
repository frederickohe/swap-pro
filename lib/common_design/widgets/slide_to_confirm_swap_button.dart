import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:swappro/common_design/app_typography.dart';

/// Slide-to-confirm control: drag the swap thumb across the track, then morph to a
/// circular progress state while [onConfirm] runs.
class SlideToConfirmSwapButton extends StatefulWidget {
  const SlideToConfirmSwapButton({
    super.key,
    required this.onConfirm,
    this.loading = false,
    this.enabled = true,
    this.height = 62,
    this.trackColor = const Color(0xFF111111),
  });

  final Future<void> Function() onConfirm;
  final bool loading;
  final bool enabled;
  final double height;
  final Color trackColor;

  @override
  State<SlideToConfirmSwapButton> createState() =>
      _SlideToConfirmSwapButtonState();
}

class _SlideToConfirmSwapButtonState extends State<SlideToConfirmSwapButton>
    with TickerProviderStateMixin {
  static const double _thumbSize = 44;
  static const double _horizontalInset = 4;
  static const double _completeThreshold = 0.88;

  double _dragOffset = 0;
  double _maxDrag = 0;
  bool _confirmed = false;
  bool _confirmInFlight = false;

  late final AnimationController _morphController;
  late final Animation<double> _morph;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _morph = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(SlideToConfirmSwapButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loading && !widget.loading && !_confirmInFlight) {
      _reset();
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  void _reset() {
    _morphController.reset();
    setState(() {
      _dragOffset = 0;
      _confirmed = false;
      _confirmInFlight = false;
    });
  }

  bool get _locked =>
      !widget.enabled || widget.loading || _confirmed || _confirmInFlight;

  Future<void> _onDragEnd() async {
    if (_locked || _maxDrag <= 0) return;

    final ratio = _dragOffset / _maxDrag;
    if (ratio < _completeThreshold) {
      setState(() => _dragOffset = 0);
      return;
    }

    setState(() {
      _dragOffset = _maxDrag;
      _confirmed = true;
    });
    await _morphController.forward();
    if (!mounted) return;

    setState(() => _confirmInFlight = true);
    await widget.onConfirm();
    if (!mounted) return;
    setState(() => _confirmInFlight = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        _maxDrag = math.max(0, trackWidth - _thumbSize - _horizontalInset * 2);

        final morphed = _morph.value > 0.01;
        final showProgress = widget.loading || _confirmInFlight;

        return AnimatedBuilder(
          animation: _morph,
          builder: (context, _) {
            final morph = _morph.value;
            final dragRatio = _maxDrag > 0 ? (_dragOffset / _maxDrag) : 0.0;
            final width = morphed
                ? trackWidth - (trackWidth - widget.height) * morph
                : trackWidth;
            final radius = widget.height / 2;
            final labelOpacity = ((1 - morph * 1.4) * (1 - dragRatio * 0.55))
                .clamp(0.0, 1.0);
            final showThumb = morph < 0.12 && !showProgress;

            return Align(
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: Duration.zero,
                width: width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.trackColor,
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    if (!morphed || labelOpacity > 0.05)
                      Opacity(
                        opacity: labelOpacity,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: _thumbSize + _horizontalInset + 8,
                            right: 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Swipe to Swap',
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.style(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (showProgress && morph >= 0.55)
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    else if (showThumb)
                      Positioned(
                        left: _horizontalInset + _dragOffset,
                        top: (widget.height - _thumbSize) / 2,
                        child: _SwapThumb(
                          size: _thumbSize,
                          onHorizontalDragUpdate: _locked
                              ? null
                              : (details) {
                                  setState(() {
                                    _dragOffset =
                                        (_dragOffset + details.delta.dx).clamp(
                                          0.0,
                                          _maxDrag,
                                        );
                                  });
                                },
                          onHorizontalDragEnd: _locked
                              ? null
                              : (_) => _onDragEnd(),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SwapThumb extends StatelessWidget {
  const _SwapThumb({
    required this.size,
    this.onHorizontalDragUpdate,
    this.onHorizontalDragEnd,
  });

  final double size;
  final GestureDragUpdateCallback? onHorizontalDragUpdate;
  final GestureDragEndCallback? onHorizontalDragEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Transform.rotate(
            angle: 1.5708,
            child: const Icon(
              Icons.swap_calls,
              size: 26,
              color: Color(0xFF111111),
            ),
          ),
        ),
      ),
    );
  }
}
