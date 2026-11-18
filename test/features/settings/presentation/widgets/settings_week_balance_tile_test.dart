// The week balance row of the settings (#911, K4).
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/features/settings/presentation/widgets/settings_week_balance_tile.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../calories/support/fake_calories_repositories.dart';

Future<FakeCalorieSettingsRepository> _pump(
  WidgetTester tester, {
  WeekBalanceMode mode = WeekBalanceMode.off,
}) async {
  final repository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2200,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 11, 16),
    ).copyWith(weekBalanceMode: mode),
  );
  addTearDown(repository.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 19, 10)),
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SettingsWeekBalanceTile()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

void main() {
  testWidgets('K4: the row offers "Aus", "Anzeigen" and "Mit Übertrag"', (
    tester,
  ) async {
    await _pump(tester);

    final tile = find.byKey(SettingsPageKeys.weekBalanceTile);
    expect(tile, findsOneWidget);
    expect(
      find.descendant(of: tile, matching: find.text('Wochenzielbalance')),
      findsOneWidget,
    );
    for (final label in ['Aus', 'Anzeigen', 'Mit Übertrag']) {
      expect(
        find.descendant(of: tile, matching: find.text(label)),
        findsOneWidget,
      );
    }
    // K35: the same line as in the menu.
    expect(
      find.text('Gleicht die Woche aus, höchstens 350 kcal pro Tag.'),
      findsOneWidget,
    );
  });

  testWidgets('K4: picking "Mit Übertrag" there stores it', (tester) async {
    final repository = await _pump(tester);
    expect(
      find.descendant(
        of: find.byKey(WeekBalanceModeKeys.option(WeekBalanceMode.off)),
        matching: find.byKey(WeekBalanceModeKeys.selected),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(WeekBalanceModeKeys.option(WeekBalanceMode.carryover)),
    );
    await tester.pumpAndSettle();

    expect(
      (await repository.readSettings()).weekBalanceMode,
      WeekBalanceMode.carryover,
    );
    expect(
      find.descendant(
        of: find.byKey(WeekBalanceModeKeys.option(WeekBalanceMode.carryover)),
        matching: find.byKey(WeekBalanceModeKeys.selected),
      ),
      findsOneWidget,
    );
  });
}
