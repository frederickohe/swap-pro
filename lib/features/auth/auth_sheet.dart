import 'package:swappro/barrel.dart';

/// Bottom sheet login prompt — mirrors the web [AuthSheet] guest-browse flow.
///
/// Guests can dismiss and keep browsing; signing in pops `true` so callers
/// (via [ensureAuthenticated]) can resume the intended account action.
class AuthSheet extends StatelessWidget {
  const AuthSheet({
    super.key,
    this.sessionExpired = false,
  });

  final bool sessionExpired;

  static const Color _ink = Color(0xFF111111);
  static const Color _inkSoft = Color(0xFF787676);
  static const Color _handle = Color(0xFFDDDDDD);
  static const Color _closeBg = Color(0xFFF3F3F3);
  static const Color _infoBg = Color(0xFFF8F6E8);
  static const Color _gold = Color(0xFFC3B649);

  /// Opens the auth sheet. Returns `true` only if the user authenticated.
  static Future<bool> show(
    BuildContext context, {
    bool sessionExpired = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => AuthSheet(sessionExpired: sessionExpired),
    );
    return result == true;
  }

  Future<void> _openSignIn(BuildContext context) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const Signin(resumeCallerOnSuccess: true),
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _openSignUp(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Signup(),
      ),
    );
    if (context.mounted && isAuthenticated(context)) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 480),
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottomInset),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _handle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sessionExpired ? 'Welcome back' : 'Ready to Swap?',
                          style: AppTypography.style(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            height: 1.2,
                          ),
                        ),
                      ),
                      Material(
                        color: _closeBg,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.of(context).pop(false),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(Icons.close, size: 20, color: _ink),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sign in to list items and swap.',
                      style: AppTypography.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: _inkSoft,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (sessionExpired) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _infoBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 18,
                            color: _ink,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your session expired. Please sign in again.',
                              style: AppTypography.style(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icons/logo.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SwapLottieView(width: 160, height: 160),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => _openSignIn(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: const BorderSide(color: _ink, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      child: Text(
                        'Log in',
                        style: AppTypography.style(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _openSignUp(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _ink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Create Account',
                        style: AppTypography.style(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Continue browsing',
                      style: AppTypography.style(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
