import 'dart:async';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_preferences.g.dart';

abstract interface class AppPreferences {
  Future<String?> getString(String key);
  Future<int?> getInt(String key);
  Future<bool> setString(String key, String value);
  Future<bool> setInt(String key, int value);
}

class SharedPreferencesStore implements AppPreferences {
  SharedPreferencesStore({SharedPreferences? preferences})
    : _preferences = preferences;

  SharedPreferences? _preferences;
  final Map<String, Object> _memoryFallback = <String, Object>{};

  Future<SharedPreferences?> _instance() async {
    if (_preferences != null) {
      return _preferences;
    }

    try {
      _preferences = await SharedPreferences.getInstance();
      return _preferences;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<String?> getString(String key) async {
    final preferences = await _instance();
    if (preferences != null) {
      return preferences.getString(key);
    }
    return _memoryFallback[key] as String?;
  }

  @override
  Future<int?> getInt(String key) async {
    final preferences = await _instance();
    if (preferences != null) {
      return preferences.getInt(key);
    }
    return _memoryFallback[key] as int?;
  }

  @override
  Future<bool> setString(String key, String value) async {
    final preferences = await _instance();
    if (preferences != null) {
      return preferences.setString(key, value);
    }
    _memoryFallback[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    final preferences = await _instance();
    if (preferences != null) {
      return preferences.setInt(key, value);
    }
    _memoryFallback[key] = value;
    return true;
  }
}

@Riverpod(keepAlive: true)
AppPreferences appPreferences(Ref ref) {
  return SharedPreferencesStore();
}
