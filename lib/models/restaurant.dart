import 'package:flutter/material.dart';
import 'package:cyber_table_order/models/app_preferences.dart';
import 'package:cyber_table_order/models/food.dart';
import 'package:cyber_table_order/models/food_catalog.dart';
import 'package:cyber_table_order/utils/translations.dart';

class Restaurant extends ChangeNotifier {
  static const Set<String> _supportedLanguageCodes = {'en', 'zh', 'ja'};
  static const _languagePreferenceKey = 'app_language_code';

  final AppPreferencesStorage preferences;
  final AppPreferencesWriteQueue _preferenceWrites = AppPreferencesWriteQueue();
  String _languageCode = 'en';
  bool _isLoaded = false;

  Restaurant({AppPreferencesStorage? preferences})
      : preferences = preferences ?? SharedPreferencesAppPreferencesStorage();

  String get languageCode => _languageCode;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final storedCode = await preferences.getString(_languagePreferenceKey);
    if (storedCode != null && _supportedLanguageCodes.contains(storedCode)) {
      _languageCode = storedCode;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (!_supportedLanguageCodes.contains(code) || code == _languageCode) {
      return;
    }
    _languageCode = code;
    notifyListeners();
    await _preferenceWrites.setString(
      preferences,
      _languagePreferenceKey,
      code,
    );
  }

  String translate(String key) {
    return Translations.get(key, _languageCode);
  }

  String foodName(Food food) => translate(food.nameKey);

  String foodDescription(Food food) => translate(food.descriptionKey);

  List<Food> getMenu() {
    return FoodCatalog.items;
  }

  List<Food> getMenuByTag(String tag) {
    if (tag.isEmpty) return getMenu();
    return List.unmodifiable(
      FoodCatalog.items.where((food) => food.tags.contains(tag)),
    );
  }
}
