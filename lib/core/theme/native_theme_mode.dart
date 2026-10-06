import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

const _channel = MethodChannel('de.yamt.app/theme_mode');

/// Tells Android the brightness the user picked, so the system draws the
/// launch screen of the next cold start in it (`MainActivity.kt`, Android 12
/// and newer). Other platforms keep the system brightness there.
Future<void> applyNativeThemeMode(ThemeMode mode) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  try {
    await _channel.invokeMethod<void>('set', mode.name);
  } on MissingPluginException catch (error) {
    // Widget tests have no channel. The app theme itself still follows the
    // choice; only the launch screen keeps the system brightness.
    log('Native theme mode not set', error: error);
  }
}
