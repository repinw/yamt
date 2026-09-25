import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _fontLicenses = [
  ('Bricolage Grotesque', 'assets/fonts/BricolageGrotesque-OFL.txt'),
  ('JetBrains Mono', 'assets/fonts/JetBrainsMono-OFL.txt'),
];

/// Adds the licenses of the bundled fonts to the app's license page.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, asset) in _fontLicenses) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString(asset));
    }
  });
}
