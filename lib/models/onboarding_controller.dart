import 'package:cyber_table_order/models/app_preferences.dart';
import 'package:flutter/foundation.dart';

class OnboardingController extends ChangeNotifier {
  static const totalSteps = 3;
  static const _stepPreferenceKey = 'app_onboarding_step_v1';

  final AppPreferencesStorage preferences;
  final AppPreferencesWriteQueue _preferenceWrites = AppPreferencesWriteQueue();
  int _step = 0;
  bool _isLoaded = false;

  OnboardingController({AppPreferencesStorage? preferences})
      : preferences = preferences ?? SharedPreferencesAppPreferencesStorage();

  int get step => _step;
  bool get isLoaded => _isLoaded;
  bool get isComplete => _step >= totalSteps;

  Future<void> load() async {
    final storedStep = int.tryParse(
      await preferences.getString(_stepPreferenceKey) ?? '',
    );
    _step = (storedStep ?? 0).clamp(0, totalSteps);
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> advance() async {
    if (isComplete) return;
    _step += 1;
    notifyListeners();
    await _persistStep();
  }

  Future<void> complete() async {
    if (isComplete) return;
    _step = totalSteps;
    notifyListeners();
    await _persistStep();
  }

  Future<void> _persistStep() {
    return _preferenceWrites.setString(
      preferences,
      _stepPreferenceKey,
      _step.toString(),
    );
  }
}
