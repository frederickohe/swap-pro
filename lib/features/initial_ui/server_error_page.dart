import 'package:swappro/barrel.dart';
import 'package:swappro/services/backend_connectivity.dart';

class ServerErrorPage extends StatefulWidget {
  const ServerErrorPage({
    super.key,
    this.onRetry,
    this.title,
    this.message,
    this.popAfterRetry = false,
  });

  final Future<void> Function()? onRetry;
  final String? title;
  final String? message;

  /// When true, pops this page after a successful retry (in-app error overlay).
  final bool popAfterRetry;

  @override
  State<ServerErrorPage> createState() => _ServerErrorPageState();
}

class _ServerErrorPageState extends State<ServerErrorPage> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    try {
      final reachable = await BackendConnectivity.isReachable();
      if (!reachable || !mounted) return;

      appConnectivityNotifier.clear();
      if (widget.onRetry != null) {
        await widget.onRetry!();
      }
      if (widget.popAfterRetry && mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  void _navigateFromAuthState(AuthState state) {
    if (!mounted) return;
    if (state is Authenticated || state is TokenRefreshed) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeEntry()),
        (route) => false,
      );
    } else if (state is Unauthenticated ||
        state is SessionExpired ||
        state is TokenRefreshFailed) {
      // Guests may browse without an account.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeEntry()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wScale = size.width / 430;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _navigateFromAuthState(state),
      child: AppScaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32 * wScale),
            child: Column(
              children: [
                const Spacer(flex: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20 * wScale),
                  child: Image.asset(
                    'assets/icons/logo.png',
                    width: 68 * wScale,
                    height: 64 * wScale,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: 24 * wScale),
                Text(
                  widget.title ?? 'Cannot reach server',
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 24 * wScale,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111111),
                  ),
                ),
                SizedBox(height: 12 * wScale),
                Text(
                  widget.message ??
                      'Swap Pro could not connect to the backend. '
                          'Check your internet connection and try again.',
                  textAlign: TextAlign.center,
                  style: AppTypography.style(
                    fontSize: 14 * wScale,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF787676),
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: 277 * wScale,
                  height: 56 * wScale,
                  child: ElevatedButton(
                    onPressed: _retrying ? null : _retry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10 * wScale),
                      ),
                    ),
                    child: _retrying
                        ? const SwapproLoadingIndicator(size: 22)
                        : Text(
                            'Try again',
                            style: AppTypography.style(
                              fontSize: 14 * wScale,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 40 * wScale),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
