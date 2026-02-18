import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_preferences.g.dart';

abstract interface class AppPreferences {
  String? getStringSync(String key);
  int? getIntSync(String key);
  Future<String?> getString(String key);
  Future<int?> getInt(String key);
  Future<bool> setString(String key, String value);
  Future<bool> setInt(String key, int value);
}

class SharedPreferencesStore implements AppPreferences {
  SharedPreferencesStore({SharedPreferences? preferences})
    : _preferences = preferences,
      _instanceFuture = preferences != null
          ? Future<SharedPreferences?>.value(preferences)
          : null;

  SharedPreferences? _preferences;
  Future<SharedPreferences?>? _instanceFuture;

  Future<SharedPreferences?> _instance() {
    if (_preferences != null) {
      return Future<SharedPreferences?>.value(_preferences);
    }

    final existingFuture = _instanceFuture;
    if (existingFuture != null) {
      return existingFuture;
    }

    final createdFuture = _loadPreferences();
    _instanceFuture = createdFuture;
    return createdFuture;
  }

  Future<SharedPreferences?> _loadPreferences() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _preferences = preferences;
      return preferences;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  String? getStringSync(String key) {
    final preferences = _preferences;
    if (preferences != null) {
      return preferences.getString(key);
    }
    return null;
  }

  @override
  int? getIntSync(String key) {
    final preferences = _preferences;
    if (preferences != null) {
      return preferences.getInt(key);
    }
    return null;
  }

  @override
  Future<String?> getString(String key) async {
    final preferences = await _instance();
    if (preferences != null) {
      return preferences.getString(key);
    }
    return null;
  }

  @override
  Future<int?> getInt(String key) async {
    final preferences = await _instance();
    if (preferences != null) {
      return preferences.getInt(key);
    }
    return null;
  }

  @override
  Future<bool> setString(String key, String value) async {
    final preferences = await _instance();
    if (preferences != null) {
      return preferences.setString(key, value);
    }
    return false;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    final preferences = await _instance();
    if (preferences != null) {
      return preferences.setInt(key, value);
    }
    return false;
  }
}

@Riverpod(keepAlive: true)
AppPreferences appPreferences(Ref ref) {
  return SharedPreferencesStore();
}
