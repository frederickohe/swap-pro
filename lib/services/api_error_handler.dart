import 'package:swappro/barrel.dart';

/// Central handling for API and network failures — never surfaces raw exceptions in UI.
class ApiErrorHandler {
  ApiErrorHandler._();

  static bool isSessionExpired(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('session expired') ||
        message.contains('token expired') ||
        message.contains('please log in again') ||
        message.contains('please sign in again');
  }

  static bool isNetworkFailure(Object error) {
    return BackendConnectivity.isNetworkFailure(error) ||
        _messageLooksLikeNetwork(error.toString());
  }

  static bool _messageLooksLikeNetwork(String message) {
    final lower = message.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('connection timed out') ||
        lower.contains('network is unreachable') ||
        lower.contains('clientexception');
  }

  /// Returns `true` when the error was handled (navigation / auth flow triggered).
  static Future<bool> handle(
    BuildContext context,
    Object error, {
    Future<void> Function()? onRetry,
    bool popAfterRetry = true,
  }) async {
    if (!context.mounted) return true;

    if (isSessionExpired(error)) {
      context.read<AuthBloc>().add(const SessionExpiredEvent());
      return true;
    }

    final isNetwork = isNetworkFailure(error);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'ServerErrorPage'),
        builder: (pageContext) => ServerErrorPage(
          title: isNetwork ? 'Cannot reach server' : 'Something went wrong',
          message: isNetwork
              ? 'Swap Pro could not connect to the backend. '
                  'Check your internet connection and try again.'
              : 'We could not complete your request. Please try again.',
          popAfterRetry: popAfterRetry,
          onRetry: onRetry,
        ),
      ),
    );
    return true;
  }
}
