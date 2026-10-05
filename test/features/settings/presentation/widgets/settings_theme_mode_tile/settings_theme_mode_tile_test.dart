import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_theme.dart';
import 'package:yamt/core/theme/app_theme_mode_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_theme_mode_tile/settings_theme_mode_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../../helpers/memory_app_preferences.dart';

void main() {
  testWidgets('a segment switches the app brightness and saves the choice', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final preferences = MemoryAppPreferences();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPreferencesProvider.overrideWithValue(preferences)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ref.watch(appThemeModeControllerProvider),
            locale: const Locale('de'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingsThemeModeTile()),
          ),
        ),
      ),
    );
    Brightness brightness() =>
        Theme.of(tester.element(find.byType(SettingsThemeModeTile))).brightness;
    expect(brightness(), Brightness.light);

    await tester.tap(
      find.byKey(SettingsThemeModeTile.segmentKey(ThemeMode.dark)),
    );
    await tester.pumpAndSettle();

    expect(brightness(), Brightness.dark);
    expect(preferences.getStringSync('app_theme_mode_v1'), 'dark');

    await tester.tap(
      find.byKey(SettingsThemeModeTile.segmentKey(ThemeMode.system)),
    );
    await tester.pumpAndSettle();

    expect(brightness(), Brightness.light);
    expect(preferences.getStringSync('app_theme_mode_v1'), 'system');
  });
}
