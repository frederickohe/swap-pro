import 'package:swappro/barrel.dart';

class OnboardingService {
  static const String _doneKey = 'ftu_onboarding_done_v1';

  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_doneKey) ?? false;
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneKey, true);
  }

  Future<void> resetForDebug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_doneKey);
  }
}

