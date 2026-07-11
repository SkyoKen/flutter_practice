import 'package:shared_preferences/shared_preferences.dart';

abstract class AppPreferencesStorage {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}

class AppPreferencesWriteQueue {
  Future<void> _tail = Future<void>.value();

  Future<void> setString(
    AppPreferencesStorage storage,
    String key,
    String value,
  ) {
    final operation = _tail.then((_) => storage.setString(key, value));
    _tail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return operation;
  }
}

class SharedPreferencesAppPreferencesStorage implements AppPreferencesStorage {
  Future<SharedPreferences> get _preferences => SharedPreferences.getInstance();

  @override
  Future<String?> getString(String key) async {
    return (await _preferences).getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    await (await _preferences).setString(key, value);
  }
}

class MemoryAppPreferencesStorage implements AppPreferencesStorage {
  final Map<String, String> values;

  MemoryAppPreferencesStorage([Map<String, String>? values])
      : values = values ?? <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
