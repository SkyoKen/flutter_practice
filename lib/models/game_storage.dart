import 'package:shared_preferences/shared_preferences.dart';

abstract class GameStorage {
  Future<double?> getDouble(String key);
  Future<int?> getInt(String key);
  Future<String?> getString(String key);
  Future<void> setDouble(String key, double value);
  Future<void> setInt(String key, int value);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
  Future<void> clearGameData();
}

class SharedPreferencesGameStorage implements GameStorage {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<double?> getDouble(String key) async {
    return (await _prefs).getDouble(key);
  }

  @override
  Future<int?> getInt(String key) async {
    return (await _prefs).getInt(key);
  }

  @override
  Future<String?> getString(String key) async {
    return (await _prefs).getString(key);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    final saved = await (await _prefs).setDouble(key, value);
    if (!saved) throw StateError('Failed to save $key');
  }

  @override
  Future<void> setInt(String key, int value) async {
    final saved = await (await _prefs).setInt(key, value);
    if (!saved) throw StateError('Failed to save $key');
  }

  @override
  Future<void> setString(String key, String value) async {
    final saved = await (await _prefs).setString(key, value);
    if (!saved) throw StateError('Failed to save $key');
  }

  @override
  Future<void> remove(String key) async {
    await (await _prefs).remove(key);
  }

  @override
  Future<void> clearGameData() async {
    final prefs = await _prefs;
    final gameKeys = prefs
        .getKeys()
        .where((key) => key.startsWith('idle_'))
        .toList(growable: false);
    for (final key in gameKeys) {
      await prefs.remove(key);
    }
  }
}

class MemoryGameStorage implements GameStorage {
  final Map<String, Object> _values;

  MemoryGameStorage([Map<String, Object>? values]) : _values = values ?? {};

  @override
  Future<double?> getDouble(String key) async {
    final value = _values[key];
    return value is num ? value.toDouble() : null;
  }

  @override
  Future<int?> getInt(String key) async {
    final value = _values[key];
    return value is num ? value.toInt() : null;
  }

  @override
  Future<String?> getString(String key) async {
    final value = _values[key];
    return value is String ? value : null;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    _values[key] = value;
  }

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<void> clearGameData() async {
    _values.removeWhere((key, value) => key.startsWith('idle_'));
  }

  Map<String, Object> get values => Map.unmodifiable(_values);
}
