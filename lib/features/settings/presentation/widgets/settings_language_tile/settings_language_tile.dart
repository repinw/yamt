import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Settings row that shows the current app language.
class SettingsLanguageTile extends StatelessWidget {
  /// Creates the language row.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final languageLabels = <String, String>{
      for (final locale in AppLocalizations.supportedLocales)
        locale.languageCode: _localizedLanguageLabel(l10n, locale),
    };
    final language = languageLabels[languageCode] ?? languageCode;

    return SettingsTile(
      key: SettingsPageKeys.languageTile,
      icon: Icons.language_rounded,
      title: l10n.settingsLanguageTitle,
      subtitle: language,
      onTap: () => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.commonNotImplementedYet))),
    );
  }
}

String _localizedLanguageLabel(AppLocalizations l10n, Locale locale) {
  return switch (locale.languageCode) {
    'de' => l10n.settingsLanguageGerman,
    'en' => l10n.settingsLanguageEnglish,
    _ => locale.languageCode,
  };
}
