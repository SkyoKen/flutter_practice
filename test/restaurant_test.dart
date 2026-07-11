import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_table_order/models/app_preferences.dart';
import 'package:cyber_table_order/models/restaurant.dart';

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
  group('Restaurant', () {
    test('defaults to English', () {
      final restaurant = Restaurant();

      expect(restaurant.languageCode, 'en');
      expect(restaurant.translate('start_session'), 'START BUSINESS');
    });

    test('switches between supported languages without duplicate notices',
        () async {
      final preferences = MemoryAppPreferencesStorage();
      final restaurant = Restaurant(preferences: preferences);
      var notifications = 0;
      restaurant.addListener(() => notifications += 1);

      restaurant.setLanguage('en');
      expect(notifications, 0);

      await restaurant.setLanguage('zh');
      expect(restaurant.languageCode, 'zh');
      expect(restaurant.translate('start_session'), '开始营业');

      await restaurant.setLanguage('ja');
      expect(restaurant.languageCode, 'ja');
      expect(restaurant.translate('start_session'), '営業を開始');

      await restaurant.setLanguage('en');
      expect(restaurant.languageCode, 'en');
      expect(restaurant.translate('start_session'), 'START BUSINESS');
      expect(notifications, 3);
      expect(preferences.values['app_language_code'], 'en');
    });

    test('rapid language changes persist the last selection', () async {
      final preferences = _DelayedPreferencesStorage([
        const Duration(milliseconds: 30),
        Duration.zero,
      ]);
      final restaurant = Restaurant(preferences: preferences);

      final firstChange = restaurant.setLanguage('zh');
      final lastChange = restaurant.setLanguage('ja');

      expect(restaurant.languageCode, 'ja');
      await Future.wait([firstChange, lastChange]);
      expect(preferences.values['app_language_code'], 'ja');
    });

    test('ignores unsupported languages', () {
      final restaurant = Restaurant();
      var notifications = 0;
      restaurant.addListener(() => notifications += 1);

      restaurant.setLanguage('fr');
      restaurant.setLanguage('');

      expect(restaurant.languageCode, 'en');
      expect(restaurant.translate('start_session'), 'START BUSINESS');
      expect(notifications, 0);
    });

    test('restores a supported language and rejects corrupt preferences',
        () async {
      final stored = Restaurant(
        preferences: MemoryAppPreferencesStorage({
          'app_language_code': 'ja',
        }),
      );
      await stored.load();

      expect(stored.isLoaded, isTrue);
      expect(stored.languageCode, 'ja');

      final corrupt = Restaurant(
        preferences: MemoryAppPreferencesStorage({
          'app_language_code': 'fr',
        }),
      );
      await corrupt.load();

      expect(corrupt.languageCode, 'en');
    });

    test('provides complete game vocabulary in every supported language',
        () async {
      final restaurant = Restaurant(
        preferences: MemoryAppPreferencesStorage(),
      );
      const coinsPerMinuteByLanguage = {
        'en': 'COINS/MIN',
        'zh': '金币/分',
        'ja': 'コイン/分',
      };
      final requiredKeys = <String>[
        'business_bottleneck_title',
        for (final bottleneck in [
          'seats',
          'kitchen',
          'dining',
          'checkout',
          'balanced',
        ])
          'business_bottleneck_$bottleneck',
        'upgrade_preview_current',
        'upgrade_preview_projected',
        'upgrade_preview_gain',
        'upgrade_recommended',
        'upgrade_next_best',
        'upgrade_action',
        'upgrade_payback',
        'upgrade_minutes_short',
        'upgrade_shortfall',
        'business_throughput',
        'business_orders_per_min',
        'business_queue',
        'business_seat_load',
        'idle_save_failed',
        'idle_retry',
        'rewards_ready_title',
        'goals_in_progress_title',
        'claimed_rewards_title',
        'rush_expected_bill',
        'rush_dish_book',
        'onboarding_title',
        'onboarding_auto_title',
        'onboarding_auto_description',
        'onboarding_upgrade_title',
        'onboarding_upgrade_description',
        'onboarding_rush_title',
        'onboarding_rush_description',
        'onboarding_skip',
        'onboarding_next',
        'onboarding_done',
        for (final theme in [
          'neon_terminal',
          'neo_brutalism',
          'paper_receipt',
          'retro_os',
        ]) ...[
          'theme_${theme}_label',
          'theme_${theme}_description',
        ],
        for (var dishId = 1; dishId <= 9; dishId++) ...[
          'dish_${dishId}_name',
          'dish_${dishId}_description',
        ],
      ];

      for (final language in coinsPerMinuteByLanguage.keys) {
        await restaurant.setLanguage(language);
        expect(
          restaurant.translate('idle_coins_per_min'),
          coinsPerMinuteByLanguage[language],
        );
        for (final key in requiredKeys) {
          expect(
            restaurant.translate(key),
            isNot(key),
            reason: '$key is missing for $language',
          );
        }
      }
    });

    test('removed table-ordering vocabulary falls back to its key', () {
      final restaurant = Restaurant();

      for (final key in [
        'member_login',
        'mobile_qr',
        'order_cart',
        'history_log',
        'call_staff',
        'idle_yen_per_min',
      ]) {
        expect(restaurant.translate(key), key);
      }
    });

    test('menu has unique IDs and filters by tag', () {
      final restaurant = Restaurant();
      final menu = restaurant.getMenu();
      final popular = restaurant.getMenuByTag('popular');

      expect(menu.map((food) => food.id).toSet(), hasLength(menu.length));
      expect(popular.map((food) => food.id), [1, 2, 4]);
      expect(popular.every((food) => food.tags.contains('popular')), isTrue);
      expect(restaurant.getMenuByTag('missing'), isEmpty);
      expect(restaurant.getMenuByTag(''), orderedEquals(menu));
    });

    test('menu lists are read-only', () {
      final restaurant = Restaurant();
      final menu = restaurant.getMenu();
      final popular = restaurant.getMenuByTag('popular');

      expect(() => menu.add(menu.first), throwsUnsupportedError);
      expect(() => popular.clear(), throwsUnsupportedError);
      expect(() => menu.first.tags.add('new'), throwsUnsupportedError);
    });
  });
}
