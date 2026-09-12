import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_tiles/settings_tiles.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Introductory text at the top of the settings page.
class SettingsIntro extends StatelessWidget {
  /// Creates the settings intro.
  const SettingsIntro({required this.l10n, super.key});

  /// Localized strings used by the intro.
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Text(
    l10n.settingsManagePreferencesSubtitle,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    ),
  );
}

/// Settings tile showing application information and version.
class SettingsAboutTile extends ConsumerWidget {
  /// Creates the about tile.
  const SettingsAboutTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final version = ref.watch(appVersionProvider);
    return SettingsTile(
      key: SettingsPageKeys.aboutTile,
      icon: Icons.info_outline_rounded,
      title: l10n.settingsAboutTitle,
      subtitle: l10n.settingsAboutSubtitle,
      trailing: switch (version) {
        AsyncData(:final value) => KeyedSubtree(
          key: SettingsPageKeys.aboutTrailing,
          child: SettingsTrailingValue(value: value),
        ),
        AsyncLoading() => const KeyedSubtree(
          key: SettingsPageKeys.aboutTrailing,
          child: SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        AsyncError() => null,
      },
      showChevron: version is! AsyncLoading,
    );
  }
}

/// Settings tile opening household settings.
class SettingsHouseholdTile extends StatelessWidget {
  /// Creates the household tile.
  const SettingsHouseholdTile({required this.l10n, super.key});

  /// Localized strings used by the tile.
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => SettingsTile(
    key: SettingsPageKeys.householdTile,
    icon: Icons.groups_2_outlined,
    title: l10n.settingsHouseholdTitle,
    subtitle: l10n.settingsHouseholdSubtitle,
    onTap: () => context.push(AppRoutes.homeSettingsHousehold),
  );
}

/// Settings tile showing the active app language.
class SettingsLanguageTile extends StatelessWidget {
  /// Creates the language tile.
  const SettingsLanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final labels = <String, String>{
      for (final locale in AppLocalizations.supportedLocales)
        locale.languageCode: _localizedLanguageLabel(l10n, locale),
    };
    return SettingsTile(
      key: SettingsPageKeys.languageTile,
      icon: Icons.language_rounded,
      title: l10n.settingsLanguageTitle,
      subtitle: labels[languageCode] ?? languageCode,
      onTap: () => showNotImplementedSettingsSnackBar(
        context,
        l10n.commonNotImplementedYet,
      ),
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

/// Shows the shared placeholder feedback for unfinished settings actions.
void showNotImplementedSettingsSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
