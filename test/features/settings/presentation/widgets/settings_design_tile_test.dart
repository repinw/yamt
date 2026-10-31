import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/theme/app_design_controller.dart';
import 'package:yamt/core/theme/app_themes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_custom_colors/settings_custom_base_dialog.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_design_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';

Future<MemoryAppPreferences> _pumpTile(WidgetTester tester) async {
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final preferences = MemoryAppPreferences();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      child: Consumer(
        builder: (context, ref, _) {
          final themes = ref.watch(appThemesProvider);
          return MaterialApp(
            theme: themes.light,
            darkTheme: themes.dark,
            themeMode: themes.mode,
            locale: const Locale('de'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SettingsDesignTile()),
          );
        },
      ),
    ),
  );
  return preferences;
}

Brightness _brightness(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(SettingsDesignTile))).brightness;

void main() {
  testWidgets('a segment switches the app brightness and saves the choice', (
    tester,
  ) async {
    final preferences = await _pumpTile(tester);
    expect(_brightness(tester), Brightness.light);

    await tester.tap(find.byKey(SettingsDesignTile.segmentKey(AppDesign.dark)));
    await tester.pumpAndSettle();

    expect(_brightness(tester), Brightness.dark);
    expect(preferences.getStringSync('app_theme_mode_v1'), 'dark');

    await tester.tap(
      find.byKey(SettingsDesignTile.segmentKey(AppDesign.system)),
    );
    await tester.pumpAndSettle();

    expect(_brightness(tester), Brightness.light);
    expect(preferences.getStringSync('app_theme_mode_v1'), 'system');
  });

  testWidgets('the first switch to custom asks for the design to copy', (
    tester,
  ) async {
    final preferences = await _pumpTile(tester);

    await tester.tap(
      find.byKey(SettingsDesignTile.segmentKey(AppDesign.custom)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(SettingsCustomBaseDialog.optionKey(Brightness.dark)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsCustomBaseDialog), findsNothing);
    expect(_brightness(tester), Brightness.dark);
    expect(
      FoodLabelColors.of(tester.element(find.byType(SettingsDesignTile))).paper,
      FoodLabelColors.dark.paper,
    );
    expect(preferences.getStringSync('app_theme_mode_v1'), 'custom');
    expect(preferences.getStringSync('app_custom_colors_v1'), isNotNull);

    // Once the colors exist, custom switches without asking again.
    await tester.tap(
      find.byKey(SettingsDesignTile.segmentKey(AppDesign.light)),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(SettingsDesignTile.segmentKey(AppDesign.custom)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SettingsCustomBaseDialog), findsNothing);
    expect(_brightness(tester), Brightness.dark);
  });

  testWidgets('cancel keeps the current design', (tester) async {
    final preferences = await _pumpTile(tester);

    await tester.tap(
      find.byKey(SettingsDesignTile.segmentKey(AppDesign.custom)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(preferences.getStringSync('app_theme_mode_v1'), isNull);
    expect(preferences.getStringSync('app_custom_colors_v1'), isNull);
  });
}
