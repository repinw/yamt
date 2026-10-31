import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/theme/app_accent.dart';
import 'package:yamt/core/theme/app_custom_colors.dart';
import 'package:yamt/core/theme/app_design_controller.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_themes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/core/widgets/app_color_picker.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/settings_custom_colors_page.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_accent_tile/settings_accent_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_base_dialog.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_color_panel.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_color_strip.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_design_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/helpers/memory_app_preferences.dart';

/// Opens the settings page at the Appearance section, in an app themed by
/// `appThemesProvider` like `lib/app.dart`, with the color editor route.
Future<MemoryAppPreferences> _pumpSettings(WidgetTester tester) async {
  final preferences = MemoryAppPreferences();
  final settingsRepository = FakeCalorieSettingsRepository();
  addTearDown(settingsRepository.dispose);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: SettingsPage(revealAppearance: true)),
      ),
      GoRoute(
        path: AppRoutes.homeSettingsCustomColors,
        builder: (context, state) => const SettingsCustomColorsPage(),
      ),
    ],
  );
  addTearDown(router.dispose);

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
          final themes = ref.watch(appThemesProvider);
          return MaterialApp.router(
            theme: themes.light,
            darkTheme: themes.dark,
            themeMode: themes.mode,
            locale: const Locale('de'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
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

  for (final design in [AppDesign.light, AppDesign.dark]) {
    testWidgets('a design and every accent recolor the app (${design.name})', (
      tester,
    ) async {
      final preferences = await _pumpSettings(tester);

      final tile = find.byKey(SettingsPageKeys.accentTile);
      expect(tile.hitTestable(), findsOneWidget);
      await tester.tap(find.byKey(SettingsDesignTile.segmentKey(design)));
      await tester.pumpAndSettle();
      expect(preferences.getStringSync('app_theme_mode_v1'), design.name);
      await tester.tap(tile);
      await tester.pumpAndSettle();

      final sheet = find.byType(SettingsAccentSheet);
      for (final accent in AppAccent.values) {
        await tester.tap(find.byKey(SettingsAccentSheet.swatchKey(accent)));
        await tester.pumpAndSettle();

        final theme = Theme.of(tester.element(sheet));
        expect(
          theme.brightness,
          design == AppDesign.dark ? Brightness.dark : Brightness.light,
        );
        expect(
          theme.colorScheme.primary,
          accent.tonesFor(theme.brightness).fill,
        );
        expect(preferences.getStringSync('app_accent_v1'), accent.name);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('custom starts as a copy, and a picked macro color recolors '
      'the app', (tester) async {
    final preferences = await _pumpSettings(tester);

    await tester.tap(
      find.byKey(SettingsDesignTile.segmentKey(AppDesign.custom)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(SettingsCustomBaseDialog.optionKey(Brightness.dark)),
    );
    await tester.pumpAndSettle();
    expect(preferences.getStringSync('app_theme_mode_v1'), 'custom');
    expect(find.byKey(SettingsPageKeys.accentTile), findsNothing);

    final tile = find.byKey(SettingsPageKeys.customColorsTile);
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsCustomColorsPage), findsOneWidget);

    await tester.tap(
      find.byKey(SettingsCustomColorStrip.swatchKey(AppCustomColor.fat)),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byKey(AppColorPicker.wheelKey)) +
          const Offset(-60, -60),
    );
    await tester.tap(find.byKey(SettingsCustomColorPanel.applyKey));
    await tester.pumpAndSettle();

    // The whole app, the editor too, takes the color; the rest stays the
    // dark design it started from.
    final page = tester.element(find.byType(SettingsCustomColorsPage));
    final darkFat = AppTheme.dark().extension<MetricAccentColors>()!.fat;
    expect(Theme.of(page).extension<MetricAccentColors>()!.fat, isNot(darkFat));
    expect(Theme.of(page).brightness, Brightness.dark);
    expect(
      Theme.of(tester.element(find.byType(Scaffold).last))
          .extension<MetricAccentColors>()!
          .fat,
      Theme.of(page).extension<MetricAccentColors>()!.fat,
    );
    expect(
      Theme.of(tester.element(find.byType(Scaffold).last)).colorScheme.surface,
      FoodLabelColors.dark.paper,
    );

    await tester.tap(find.byKey(SettingsCustomColorsPage.resetKey));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(SettingsCustomBaseDialog.optionKey(Brightness.dark)),
    );
    await tester.pumpAndSettle();
    expect(Theme.of(page).extension<MetricAccentColors>()!.fat, darkFat);
    expect(tester.takeException(), isNull);
  });
}
