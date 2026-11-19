// The mode of the week balance (#911), picked where the user picks it: in
// the menu of the diary's week card, which a long press opens, and in the
// settings row. Widgets are found by key.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/app_version_provider.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/core/widgets/app_snack_bar_view.dart';
import 'package:yamt/features/auth/data/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/features/health/data/'
    'health_connection_service_provider.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page.dart';
import 'package:yamt/features/settings/presentation/pages/settings_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../test/features/calories/support/fake_calories_repositories.dart';
import '../../test/features/diary/acceptance/acceptance_harness.dart' as diary;
import '../../test/helpers/long_press_test_utils.dart';
import '../../test/helpers/memory_app_preferences.dart';

Finder _option(WeekBalanceMode mode, {Finder? within}) {
  final option = find.byKey(WeekBalanceModeKeys.option(mode));
  return within == null
      ? option
      : find.descendant(of: within, matching: option);
}

/// The mode whose option holds the selected mark.
WeekBalanceMode? _selected({Finder? within}) {
  for (final mode in WeekBalanceMode.values) {
    final mark = find.descendant(
      of: _option(mode, within: within),
      matching: find.byKey(WeekBalanceModeKeys.selected),
    );
    if (mark.evaluate().isNotEmpty) return mode;
  }
  return null;
}

String _budgetKcal(WidgetTester tester) =>
    diary.textUnder(tester, find.byKey(DiaryBudgetCardKeys.kcalValue));

Future<void> _openWeekCardMenu(WidgetTester tester) async {
  await longPressOpeningRoute(tester, find.byKey(DiaryWeekCardKeys.card));
  await diary.settle(tester);
  expect(find.byKey(DiaryWeekCardKeys.menu), findsOneWidget);
}

Future<void> _pickInMenu(WidgetTester tester, WeekBalanceMode mode) async {
  final option = _option(mode, within: find.byKey(DiaryWeekCardKeys.menu));
  await tester.ensureVisible(option);
  await tester.tap(option);
  await diary.settle(tester);
}

Future<void> _pumpSettings(
  WidgetTester tester,
  FakeCalorieSettingsRepository settings,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 19, 10)),
        authStateChangesProvider.overrideWithValue(
          const AsyncData<User?>(null),
        ),
        appVersionProvider.overrideWithValue(const AsyncData('3.10.0+43')),
        calorieSettingsRepositoryProvider.overrideWithValue(settings),
        healthConnectionServiceProvider.overrideWithValue(
          FakeHealthConnectionService(
            const HealthConnectionStatus.unsupported(),
          ),
        ),
      ],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SettingsPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.byKey(SettingsPageKeys.weekBalanceTile),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

FakeCalorieSettingsRepository _settingsRepository() {
  final repository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: 2200,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 11, 16),
    ),
  );
  addTearDown(repository.dispose);
  return repository;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('holding the week card opens its menu; a pick stores the mode, '
      'closes the menu and moves the budget', (tester) async {
    // Thursday of a run from Monday: Mo 2.200, Tu 1.900, We 3.000.
    final harness = diary.DiaryAcceptanceHarness(
      now: diary.morningOf(diary.runDay(3)),
      eaten: {
        diary.runDay(0): 2200,
        diary.runDay(1): 1900,
        diary.runDay(2): 3000,
      },
    );
    await harness.pumpDiary(tester);
    expect(_budgetKcal(tester), '2.200', reason: '"Anzeigen" keeps the goal');

    await _openWeekCardMenu(tester);
    expect(_selected(within: find.byKey(DiaryWeekCardKeys.menu)), isNotNull);
    await _pickInMenu(tester, WeekBalanceMode.carryover);

    expect(find.byKey(DiaryWeekCardKeys.menu), findsNothing);
    expect(
      (await harness.settings.readSettings()).weekBalanceMode,
      WeekBalanceMode.carryover,
    );
    expect(_budgetKcal(tester), '2.075', reason: 'balance −500 over 4 days');

    await _openWeekCardMenu(tester);
    expect(
      _selected(within: find.byKey(DiaryWeekCardKeys.menu)),
      WeekBalanceMode.carryover,
    );
    await _pickInMenu(tester, WeekBalanceMode.show);

    expect(find.byKey(DiaryWeekCardKeys.menu), findsNothing);
    expect(
      (await harness.settings.readSettings()).weekBalanceMode,
      WeekBalanceMode.show,
    );
    expect(_budgetKcal(tester), '2.200');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the settings row shows the stored mode; a tap opens the '
      'menu of the week card, a pick stores the mode, closes the menu and '
      'updates the row', (tester) async {
    final settings = _settingsRepository();
    await _pumpSettings(tester, settings);
    final tile = find.byKey(SettingsPageKeys.weekBalanceTile);
    final menu = find.byKey(DiaryWeekCardKeys.menu);

    for (final mode in WeekBalanceMode.values) {
      expect(_option(mode), findsNothing, reason: 'no options inline');
    }
    final stored = (await settings.readSettings()).weekBalanceMode;

    for (final mode in [WeekBalanceMode.carryover, WeekBalanceMode.off]) {
      await tester.tap(tile);
      await diary.settle(tester);
      expect(menu, findsOneWidget);
      if (mode == WeekBalanceMode.carryover) {
        expect(_selected(within: menu), stored);
      }
      await _pickInMenu(tester, mode);

      expect(menu, findsNothing);
      expect((await settings.readSettings()).weekBalanceMode, mode);
      await tester.tap(tile);
      await diary.settle(tester);
      expect(_selected(within: menu), mode);
      await tester.tapAt(const Offset(10, 10));
      await diary.settle(tester);
      expect(menu, findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed save from the settings row keeps the mode and shows '
      'a snack bar', (tester) async {
    final settings = _settingsRepository()..saveShouldFail = true;
    await _pumpSettings(tester, settings);
    final tile = find.byKey(SettingsPageKeys.weekBalanceTile);
    final before = (await settings.readSettings()).weekBalanceMode;

    await tester.tap(tile);
    await diary.settle(tester);
    expect(find.byKey(DiaryWeekCardKeys.menu), findsOneWidget);
    final option = _option(
      WeekBalanceMode.carryover,
      within: find.byKey(DiaryWeekCardKeys.menu),
    );
    await tester.ensureVisible(option);
    await tester.tap(option);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AppSnackBarView), findsOneWidget);
    expect((await settings.readSettings()).weekBalanceMode, before);
    expect(before, isNot(WeekBalanceMode.carryover));
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('a new goal from Thursday cuts the old run short: Thursday '
      'shows seven fields, Tuesday three', (tester) async {
    // K47: a run from Monday; the new goal of 2.000 counts from Thursday.
    final harness = diary.DiaryAcceptanceHarness(
      now: diary.morningOf(diary.runDay(3)),
      newGoal: (from: diary.runDay(3), kcal: 2000),
      eaten: {
        diary.runDay(0): 2200,
        diary.runDay(1): 1900,
        diary.runDay(2): 3000,
      },
    );
    await harness.pumpDiary(tester);
    await _openWeekCardMenu(tester);
    await _pickInMenu(tester, WeekBalanceMode.carryover);

    expect(find.byKey(DiaryWeekCardKeys.day(6)), findsOneWidget);
    expect(_budgetKcal(tester), '2.000');

    await diary.previousDay(tester, times: 2);

    expect(find.byKey(DiaryWeekCardKeys.card), findsOneWidget);
    expect(find.byKey(DiaryWeekCardKeys.day(2)), findsOneWidget);
    expect(find.byKey(DiaryWeekCardKeys.day(3)), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
