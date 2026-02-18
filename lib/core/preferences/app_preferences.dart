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
    : _preferences = preferences,
      _instanceFuture = preferences != null
          ? Future<SharedPreferences?>.value(preferences)
          : null;

  SharedPreferences? _preferences;
  Future<SharedPreferences?>? _instanceFuture;
  final Map<String, Object> _memoryFallback = <String, Object>{};

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
