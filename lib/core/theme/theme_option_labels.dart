import 'package:flutter/material.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/l10n/app_localizations.dart';

String localizedThemeModeLabel(AppLocalizations l10n, ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => l10n.settingsThemeSystem,
    ThemeMode.light => l10n.settingsThemeLight,
    ThemeMode.dark => l10n.settingsThemeDark,
  };
}

String localizedSeedColorLabel(AppLocalizations l10n, Color color) {
  final colorValue = color.toARGB32();
  if (colorValue == AppSeedColors.lime.toARGB32()) {
    return l10n.settingsColorLime;
  }
  if (colorValue == AppSeedColors.blue.toARGB32()) {
    return l10n.settingsColorBlue;
  }
  if (colorValue == AppSeedColors.teal.toARGB32()) {
    return l10n.settingsColorTeal;
  }
  if (colorValue == AppSeedColors.pink.toARGB32()) {
    return l10n.settingsColorPink;
  }
  if (colorValue == AppSeedColors.orange.toARGB32()) {
    return l10n.settingsColorOrange;
  }
  return l10n.settingsColorLime;
}
