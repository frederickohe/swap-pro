import 'package:swappro/barrel.dart';

/// Placeholder admin home until admin modules are built.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminSignIn()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'SwapPro Admin',
            style: AppTypography.style(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111111),
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => context.read<AuthBloc>().add(LogoutEvent()),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Admin dashboard',
              style: AppTypography.style(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111111),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
