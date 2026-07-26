import 'package:swappro/barrel.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  bool _navigated = false;
  Timer? _watchdog;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 25), () {
      if (!mounted || _navigated) return;
      final state = context.read<AuthBloc>().state;
      if (state is AuthLoading ||
          state is TokenRefreshing ||
          state is AuthInitial) {
        _goToServerError();
      }
    });
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    _startWatchdog();
    context.read<AuthBloc>().add(const CheckSessionEvent());
  }

  void _navigateOnce(void Function() navigate) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _watchdog?.cancel();
    navigate();
  }

  void _goToHome() {
    // HomeEntry keeps the Lottie visible until dashboard assets are ready.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeEntry()),
    );
  }

  void _goToLogorSign() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LogorSign()),
    );
  }

  void _goToServerError() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ServerErrorPage(
          onRetry: () async {
            if (!mounted) return;
            context.read<AuthBloc>().add(const CheckSessionEvent());
          },
        ),
      ),
    );
  }

  void _handleAuthState(AuthState state) {
    if (state is Authenticated || state is TokenRefreshed) {
      _navigateOnce(_goToHome);
    } else if (state is Unauthenticated ||
        state is SessionExpired ||
        state is TokenRefreshFailed) {
      _navigateOnce(_goToLogorSign);
    } else if (state is ServerUnreachable) {
      _navigateOnce(_goToServerError);
    } else if (state is AuthError && state.source == 'check_session') {
      _navigateOnce(_goToLogorSign);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthState(state),
      child: const SplashPge(),
    );
  }
}
