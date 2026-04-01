// coverage:ignore-file
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/config/firebase_config.dart';
import 'package:yamt/core/debug/app_provider_observer.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupFirebase();
  final appPreferences = await _createAppPreferences();

  runApp(
    ProviderScope(
      observers: kDebugMode
          ? const <ProviderObserver>[AppProviderObserver()]
          : const <ProviderObserver>[],
      overrides: [appPreferencesProvider.overrideWithValue(appPreferences)],
      child: const YAMT(),
    ),
  );
}

Future<AppPreferences> _createAppPreferences() async {
  try {
    final preferences = await SharedPreferences.getInstance();
    return SharedPreferencesStore(preferences: preferences);
  } on MissingPluginException {
    return SharedPreferencesStore();
  } on PlatformException {
    return SharedPreferencesStore();
  }
}
