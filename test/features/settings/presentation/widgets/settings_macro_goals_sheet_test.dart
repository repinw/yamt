import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_macro_goals_sheet/settings_macro_goals_sheet_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../helpers/memory_app_preferences.dart';

void main() {
  testWidgets('SettingsMacroGoalsSheet renders and updates settings', (
    tester,
  ) async {
    final preferences = MemoryAppPreferences();

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

    // Verify header and elements exist
    expect(find.text('Makronährstoff-Verteilung'), findsOneWidget);
    expect(
      find.byKey(SettingsMacroGoalsSheetKeys.sportActiveSwitch),
      findsOneWidget,
    );
    expect(
      find.byKey(SettingsMacroGoalsSheetKeys.proteinSlider),
      findsOneWidget,
    );
    expect(find.byKey(SettingsMacroGoalsSheetKeys.fatSlider), findsOneWidget);
    expect(find.byKey(SettingsMacroGoalsSheetKeys.resetButton), findsOneWidget);
    expect(find.byKey(SettingsMacroGoalsSheetKeys.saveButton), findsOneWidget);

    // Without training days the defaults are 1.2 P and 0.8 F
    expect(find.textContaining('1.2 g/kg'), findsOneWidget);
    expect(find.textContaining('0.8 g/kg'), findsOneWidget);

    // Toggle sport switch on -> protein rises to 1.6, fat stays 0.8
    await tester.tap(find.byKey(SettingsMacroGoalsSheetKeys.sportActiveSwitch));
    await tester.pumpAndSettle();

    expect(find.textContaining('1.6 g/kg'), findsOneWidget);
    expect(find.textContaining('0.8 g/kg'), findsOneWidget);

    // Toggle back off -> inactive defaults again
    await tester.tap(find.byKey(SettingsMacroGoalsSheetKeys.sportActiveSwitch));
    await tester.pumpAndSettle();

    // Reset button should keep inactive defaults
    await tester.ensureVisible(
      find.byKey(SettingsMacroGoalsSheetKeys.resetButton),
    );
    await tester.tap(find.byKey(SettingsMacroGoalsSheetKeys.resetButton));
    await tester.pumpAndSettle();

    expect(find.textContaining('1.2 g/kg'), findsOneWidget);
    expect(find.textContaining('0.8 g/kg'), findsOneWidget);

    // Save
    await tester.ensureVisible(
      find.byKey(SettingsMacroGoalsSheetKeys.saveButton),
    );
    await tester.tap(find.byKey(SettingsMacroGoalsSheetKeys.saveButton));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'displays budget exceeded warning and 0g carbs when goal is exceeded',
    (tester) async {
      // 900 kcal goal with 80kg male without training days:
      // 1.2 P * 80kg = 96g (384 kcal)
      // 0.8 F * 80kg = 64g (576 kcal)
      // Total: 960 kcal > 900 kcal
      final preferences = MemoryAppPreferences();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(preferences),
            calorieGoalControllerProvider.overrideWith(
              () => _FakeCalorieGoalController(
                const CalorieGoalSettings.empty().copyWith(
                  dailyKcalGoal: 900,
                  calculatorProfile: const CalorieCalculatorProfile(
                    sex: CalorieCalculatorSex.male,
                    weightKg: 80,
                    heightCm: 180,
                    ageYears: 30,
                    activityLevel: 1.55,
                    goalMode: CalorieGoalMode.maintain,
                    goalSpeedKgPerWeek: 0,
                  ),
                ),
              ),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('de'),
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SettingsMacroGoalsSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Budget exceeded warning must be visible
      expect(
        find.text('Eiweiß und Fett übersteigen das Tages-Kalorienziel'),
        findsOneWidget,
      );

      // Carbs must be 0g (0%) in the preview pill
      expect(find.text('0g'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    },
  );

  testWidgets('initializes with custom multipliers when previously stored', (
    tester,
  ) async {
    const stored = MacroGoalSettings(
      customProteinMultiplier: 2.5,
      customFatMultiplier: 1.3,
    );
    final preferences = MemoryAppPreferences(
      initialStrings: {'macro_goal_settings_v1': stored.toJsonString()},
    );

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

    // Custom values should be rendered
    expect(find.textContaining('2.5 g/kg'), findsOneWidget);
    expect(find.textContaining('1.3 g/kg'), findsOneWidget);
  });
}

class _FakeCalorieGoalController extends CalorieGoalController {
  new(this._settings);

  final CalorieGoalSettings _settings;

  @override
  CalorieGoalSettings build() {
    return _settings;
  }
}
