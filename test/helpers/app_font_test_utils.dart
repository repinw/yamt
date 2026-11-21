import 'dart:io';

import 'package:flutter/services.dart';
import 'package:yamt/core/theme/app_fonts.dart';

/// Loads the bundled app fonts (Geist, Plus Jakarta Sans, JetBrains Mono)
/// into the test engine, so text measures with real glyph widths instead of
/// the Ahem test font, which is one em wide for every character.
///
/// Call it in `setUpAll`; it runs once per test file.
Future<void> loadAppFonts() async {
  const families = {
    AppFonts.geist: [
      'Geist-Regular',
      'Geist-Medium',
      'Geist-SemiBold',
      'Geist-Bold',
      'Geist-ExtraBold',
    ],
    AppFonts.sans: [
      'PlusJakartaSans-Regular',
      'PlusJakartaSans-Medium',
      'PlusJakartaSans-SemiBold',
      'PlusJakartaSans-Bold',
      'PlusJakartaSans-ExtraBold',
    ],
    AppFonts.mono: [
      'JetBrainsMono-Regular',
      'JetBrainsMono-Medium',
      'JetBrainsMono-Bold',
    ],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }
}
