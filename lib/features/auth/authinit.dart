import 'package:swappro/barrel.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const CheckSessionEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is SessionExpired) {
          context.showAppSnackBar(state.message);
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const Signin()),
            (route) => false,
          );
        } else if (state is TokenRefreshFailed) {
          context.showAppSnackBar('Session error: ${state.message}');
        } else if (state is ServerUnreachable) {
          appConnectivityNotifier.reportUnreachable();
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          print('=== AuthWrapper State: ${state.runtimeType} ===');

          if (state is Authenticated || state is TokenRefreshed) {
            print('✓ User is Authenticated');
            return const Home();
          } else if (state is Unauthenticated) {
            print('✗ User is Unauthenticated - showing LogorSign');
            return const LogorSign();
          } else if (state is SessionExpired) {
            print('✗ Session Expired - showing LogorSign');
            return const LogorSign();
          } else if (state is AuthError) {
            print('✗ Auth Error: ${state.message}');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.showAppSnackBar(state.message);
            });
            // Render relevant page based on error source
            if (state.source == 'signup') {
              return const Signup();
            } else {
              return const Signin();
            }
          } else if (state is TokenRefreshing ||
              state is AuthInitial ||
              state is AuthLoading) {
            print('⏳ Auth loading: ${state.runtimeType}');
            return const Scaffold(
              body: Center(
                child: SwapproLoadingIndicator(size: 50, showLabel: true),
              ),
            );
          } else if (state is TokenRefreshFailed) {
            print('✗ Token Refresh Failed: ${state.message} - showing Signin');
            return const Signin();
          } else if (state is ServerUnreachable) {
            return const Scaffold(
              body: Center(
                child: SwapproLoadingIndicator(size: 50, showLabel: true),
              ),
            );
          } else {
            print('⏳ Unhandled auth state: $state');
            return const Signin();
          }
        },
      ),
    );
  }
}
