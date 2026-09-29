import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/helpers/memory_app_preferences.dart';

const _settingsKey = 'macro_goal_settings_v1';

Future<void> _pumpSheet(
  WidgetTester tester,
  MemoryAppPreferences preferences,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SettingsMacroGoalsSheet()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  final save = find.byKey(SettingsMacroGoalsSheetKeys.saveButton);
  await tester.ensureVisible(save);
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
}

Future<MacroGoalSettings?> _saved(MemoryAppPreferences preferences) async {
  return MacroGoalSettings.fromJsonString(
    await preferences.getString(_settingsKey),
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('saving without moving the protein slider keeps the default', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();
    await _pumpSheet(tester, preferences);

    expect(
      find.byKey(SettingsMacroGoalsSheetKeys.proteinSlider),
      findsOneWidget,
    );
    await _save(tester);

    expect((await _saved(preferences))?.customProteinMultiplier, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('moving the protein slider up saves more protein', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();
    await _pumpSheet(tester, preferences);

    // Without a profile the default rule gives 2.0 g/kg (80 kg, 2200 kcal,
    // carbs capped at 40 %); the slider starts there.
    final slider = find.byKey(SettingsMacroGoalsSheetKeys.proteinSlider);
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    await tester.drag(slider, const Offset(60, 0));
    await tester.pumpAndSettle();
    await _save(tester);

    expect(
      (await _saved(preferences))?.customProteinMultiplier,
      greaterThan(2.0),
    );
    expect(tester.takeException(), isNull);
  });
}
