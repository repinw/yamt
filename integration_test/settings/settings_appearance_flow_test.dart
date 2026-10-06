import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_accent_controller.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_theme_mode_controller.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_accent_tile/settings_accent_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_theme_mode_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/memory_app_preferences.dart';

/// Opens the settings page at the Appearance section, in an app themed by
/// the accent and theme mode controllers, like `lib/app.dart`.
Future<MemoryAppPreferences> _pumpSettings(WidgetTester tester) async {
  final preferences = MemoryAppPreferences();
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(settingsRepository.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(preferences),
        authStateChangesProvider.overrideWithValue(
          const AsyncData<User?>(null),
        ),
        appVersionProvider.overrideWithValue(const AsyncData('3.5.0+37')),
        calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
        healthConnectionServiceProvider.overrideWithValue(
          FakeHealthConnectionService(
            const HealthConnectionStatus(
              platform: HealthPlatform.android,
              healthConnectAvailability: HealthConnectAvailability.available,
              permissionState: HealthPermissionState.notGranted,
              historyAccess: HealthHistoryAccess.notGranted,
            ),
          ),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final accent = ref.watch(appAccentControllerProvider);
          return MaterialApp(
            theme: AppTheme.light(accent: accent),
            darkTheme: AppTheme.dark(accent: accent),
            themeMode: ref.watch(appThemeModeControllerProvider),
            locale: const Locale('de'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingsPage(revealAppearance: true)),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return preferences;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final themeMode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets(
      'a theme and every accent recolor the app (${themeMode.name})',
      (tester) async {
        final preferences = await _pumpSettings(tester);

        final tile = find.byKey(SettingsPageKeys.accentTile);
        expect(tile.hitTestable(), findsOneWidget);
        await tester.tap(
          find.byKey(SettingsThemeModeTile.segmentKey(themeMode)),
        );
        await tester.pumpAndSettle();
        expect(preferences.getStringSync('app_theme_mode_v1'), themeMode.name);
        await tester.tap(tile);
        await tester.pumpAndSettle();

        final sheet = find.byType(SettingsAccentSheet);
        for (final accent in AppAccent.values) {
          await tester.tap(find.byKey(SettingsAccentSheet.swatchKey(accent)));
          await tester.pumpAndSettle();

          final theme = Theme.of(tester.element(sheet));
          expect(
            theme.brightness,
            themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
          );
          expect(
            theme.colorScheme.primary,
            accent.tonesFor(theme.brightness).fill,
          );
          expect(preferences.getStringSync('app_accent_v1'), accent.name);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
