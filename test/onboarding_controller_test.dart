import 'package:cyber_table_order/models/app_preferences.dart';
import 'package:cyber_table_order/models/onboarding_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _DelayedPreferencesStorage extends MemoryAppPreferencesStorage {
  final List<Duration> delays;
  int _writeIndex = 0;

  _DelayedPreferencesStorage(this.delays);

  @override
  Future<void> setString(String key, String value) async {
    final delay = delays[_writeIndex++];
    await Future<void>.delayed(delay);
    await super.setString(key, value);
  }
}

void main() {
  test('onboarding progress persists and can be completed', () async {
    final preferences = MemoryAppPreferencesStorage();
    final onboarding = OnboardingController(preferences: preferences);
    await onboarding.load();

    expect(onboarding.step, 0);
    expect(onboarding.isComplete, isFalse);

    await onboarding.advance();
    expect(onboarding.step, 1);

    final resumed = OnboardingController(preferences: preferences);
    await resumed.load();
    expect(resumed.step, 1);

    await resumed.complete();
    expect(resumed.isComplete, isTrue);
    expect(preferences.values['app_onboarding_step_v1'], '3');
  });

  test('rapid onboarding changes persist the final progress', () async {
    final preferences = _DelayedPreferencesStorage([
      const Duration(milliseconds: 30),
      Duration.zero,
    ]);
    final onboarding = OnboardingController(preferences: preferences);

    final firstChange = onboarding.advance();
    final lastChange = onboarding.complete();

    expect(onboarding.step, OnboardingController.totalSteps);
    await Future.wait([firstChange, lastChange]);
    expect(preferences.values['app_onboarding_step_v1'], '3');
  });

  test('onboarding ignores corrupt saved progress', () async {
    final onboarding = OnboardingController(
      preferences: MemoryAppPreferencesStorage({
        'app_onboarding_step_v1': 'invalid',
      }),
    );

    await onboarding.load();

    expect(onboarding.step, 0);
    expect(onboarding.isComplete, isFalse);
  });
}
