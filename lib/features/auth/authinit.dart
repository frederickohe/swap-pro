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
        // Handle session expiration
        if (state is SessionExpired) {
          context.showAppSnackBar(state.message);
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/signin', (route) => false);
        }
        // Handle token refresh failure
        else if (state is TokenRefreshFailed) {
          context.showAppSnackBar('Session error: ${state.message}');
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
              body: Center(child: SwapproLoadingIndicator()),
            );
          } else if (state is TokenRefreshFailed) {
            print('✗ Token Refresh Failed: ${state.message} - showing Signin');
            return const Signin();
          } else {
            print('⏳ Unhandled auth state: $state');
            return const Signin();
          }
        },
      ),
    );
  }
}
