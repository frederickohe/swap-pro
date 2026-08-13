import 'package:swappro/barrel.dart';
import 'package:swappro/features/auth/auth_sheet.dart';

/// Whether the current auth state represents a logged-in session.
bool isLoggedIn(AuthState state) =>
    state is Authenticated || state is TokenRefreshed;

/// Returns true if the user is already authenticated.
bool isAuthenticated(BuildContext context) =>
    isLoggedIn(context.read<AuthBloc>().state);

/// Ensures the user is logged in before an account-based action.
///
/// Guests keep browsing; a login bottom sheet is shown instead of leaving the
/// current screen. Returns `true` only if they end up authenticated.
/// Callers must check [mounted] before continuing navigation.
Future<bool> ensureAuthenticated(
  BuildContext context, {
  bool sessionExpired = false,
}) async {
  if (isAuthenticated(context)) return true;

  final loggedIn = await AuthSheet.show(
    context,
    sessionExpired: sessionExpired,
  );

  if (!context.mounted) return false;
  return loggedIn || isAuthenticated(context);
}
