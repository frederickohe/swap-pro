import 'package:swappro/barrel.dart';

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({super.key});

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    context.read<AuthBloc>().add(const CheckSessionEvent());
  }

  void _goToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Home()),
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is TokenRefreshed) {
          _goToHome();
        } else if (state is Unauthenticated || state is SessionExpired) {
          _goToLogorSign();
        } else if (state is ServerUnreachable) {
          _goToServerError();
        }
      },
      child: const SplashPge(),
    );
  }
}
