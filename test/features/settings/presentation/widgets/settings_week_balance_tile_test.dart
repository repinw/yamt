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

Finder _selectedMark(WeekBalanceMode mode) => find.descendant(
  of: find.byKey(WeekBalanceModeKeys.option(mode)),
  matching: find.byKey(WeekBalanceModeKeys.selected),
);

void main() {
  testWidgets('K4: one row "Wochenzielbalance" with the mode "Aus" as '
      'subtitle and no options expanded', (tester) async {
    await _pump(tester);

    final tile = find.byKey(SettingsPageKeys.weekBalanceTile);
    expect(tile, findsOneWidget);
    expect(
      find.descendant(of: tile, matching: find.text('Wochenzielbalance')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile, matching: find.text('Aus')),
      findsOneWidget,
    );
    for (final mode in WeekBalanceMode.values) {
      expect(find.byKey(WeekBalanceModeKeys.option(mode)), findsNothing);
    }
  });

  testWidgets('K4: the subtitle names a stored "Mit Übertrag"', (tester) async {
    await _pump(tester, mode: WeekBalanceMode.carryover);

    final tile = find.byKey(SettingsPageKeys.weekBalanceTile);
    expect(
      find.descendant(of: tile, matching: find.text('Mit Übertrag')),
      findsOneWidget,
    );
  });

  testWidgets('K4: a tap opens the menu of the week card with "Aus" selected', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.byKey(SettingsPageKeys.weekBalanceTile));
    await tester.pumpAndSettle();

    final menu = find.byKey(WeekBalanceModeKeys.menu);
    expect(menu, findsOneWidget);
    expect(
      find.descendant(of: menu, matching: find.text('Wochenzielbalance')),
      findsOneWidget,
    );
    for (final mode in WeekBalanceMode.values) {
      expect(
        find.descendant(
          of: menu,
          matching: find.byKey(WeekBalanceModeKeys.option(mode)),
        ),
        findsOneWidget,
      );
    }
    // K35: the same line as in the menu of the card.
    expect(
      find.descendant(
        of: menu,
        matching: find.text(
          'Gleicht die Woche aus, höchstens 350 kcal pro Tag.',
        ),
      ),
      findsOneWidget,
    );
    expect(_selectedMark(WeekBalanceMode.off), findsOneWidget);
  });

  testWidgets('K4: picking "Mit Übertrag" stores it, closes the menu and '
      'updates the subtitle', (tester) async {
    final repository = await _pump(tester);
    final tile = find.byKey(SettingsPageKeys.weekBalanceTile);
    await tester.tap(tile);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(WeekBalanceModeKeys.option(WeekBalanceMode.carryover)),
    );
    await tester.pumpAndSettle();

    expect(
      (await repository.readSettings()).weekBalanceMode,
      WeekBalanceMode.carryover,
    );
    expect(find.byKey(WeekBalanceModeKeys.menu), findsNothing);
    expect(
      find.descendant(of: tile, matching: find.text('Mit Übertrag')),
      findsOneWidget,
    );
    expect(find.descendant(of: tile, matching: find.text('Aus')), findsNothing);
  });
}
