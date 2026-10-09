// coverage:ignore-file
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yamt/app.dart';
import 'package:yamt/core/config/firebase_config.dart';
import 'package:yamt/core/config/font_licenses.dart';
import 'package:yamt/core/debug/app_provider_observer.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();

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
