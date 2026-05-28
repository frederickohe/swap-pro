import 'package:flutter/foundation.dart';

/// Global signal that the backend cannot be reached.
class ConnectivityNotifier extends ChangeNotifier {
  bool _serverUnreachable = false;

  bool get isServerUnreachable => _serverUnreachable;

  void reportUnreachable() {
    if (_serverUnreachable) return;
    _serverUnreachable = true;
    notifyListeners();
  }

  void clear() {
    if (!_serverUnreachable) return;
    _serverUnreachable = false;
    notifyListeners();
  }
}

final ConnectivityNotifier appConnectivityNotifier = ConnectivityNotifier();
