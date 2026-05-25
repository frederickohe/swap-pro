import 'package:flutter/material.dart';
import 'package:swappro/common_design/app_typography.dart';

/// Shared layout tokens for auth screens (sign in, sign up, recovery, OTP).
abstract final class AuthScreenLayout {
  AuthScreenLayout._();

  static const Color dark = Color(0xFF111111);
  static const double figmaW = 430;
  static const double figmaH = 932;

  static ({
    double wScale,
    double hScale,
    double horizontalPad,
    double fieldHeight,
    double fieldRadius,
    double formGap,
    double buttonWidth,
    double buttonHeight,
    double buttonRadius,
  }) metrics(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wScale = size.width / figmaW;
    final hScale = size.height / figmaH;
    return (
      wScale: wScale,
      hScale: hScale,
      horizontalPad: 33 * wScale,
      fieldHeight: 70 * hScale,
      fieldRadius: 10 * wScale,
      formGap: 12 * hScale,
      buttonWidth: 277 * wScale,
      buttonHeight: 62 * hScale,
      buttonRadius: 10 * wScale,
    );
  }
}

/// Thin prefix (e.g. "Let's") + bold remainder (e.g. "Sign In").
class AuthSplitTitle extends StatelessWidget {
  const AuthSplitTitle({
    super.key,
    this.prefix = "Let's",
    required this.boldPart,
    required this.fontSize,
    this.color = AuthScreenLayout.dark,
  });

  final String prefix;
  final String boldPart;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = AppTypography.style(
      fontSize: fontSize,
      color: color,
      height: 40 / 32,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: prefix,
            style: base.copyWith(fontWeight: FontWeight.w300),
          ),
          TextSpan(
            text: ' $boldPart',
            style: base.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 35,
        width: 35,
        decoration: BoxDecoration(
          color: AuthScreenLayout.dark,
          shape: BoxShape.circle,
          border: Border.all(color: AuthScreenLayout.dark, width: 1.5),
        ),
        child: const Center(
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 17.5,
          ),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.radius,
    required this.fontSize,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double radius;
  final double fontSize;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthScreenLayout.dark,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              AuthScreenLayout.dark.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: AppTypography.style(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
