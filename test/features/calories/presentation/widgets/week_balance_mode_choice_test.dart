// The choice of the week balance mode (#911): K2 and K35 of
// lib/features/diary/CRITERIA.md.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_budget_settings_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/week_balance_mode_choice.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../support/fake_calories_repositories.dart';

final DateTime _monday = DateTime(2026, 11, 16);

FakeCalorieSettingsRepository _repository({double goal = 2200}) {
  final repository = FakeCalorieSettingsRepository(
    initialSettings: CalorieGoalSettings.single(
      dailyKcalGoal: goal,
      calculatorProfile: null,
      effectiveDate: _monday,
    ),
  );
  addTearDown(repository.dispose);
  return repository;
}

Future<void> _pump(
  WidgetTester tester,
  CalorieSettingsRepository repository, {
  required Widget child,
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 19, 10)),
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _option(WeekBalanceMode mode) =>
    find.byKey(WeekBalanceModeKeys.option(mode));

/// The mode whose option holds the selected mark.
WeekBalanceMode? _selected() {
  for (final mode in WeekBalanceMode.values) {
    final mark = find.descendant(
      of: _option(mode),
      matching: find.byKey(WeekBalanceModeKeys.selected),
    );
    if (mark.evaluate().isNotEmpty) return mode;
  }
  return null;
}

void main() {
  group('WeekBalanceModeChoice', () {
    testWidgets('K2: three options with their lines, one selected', (
      tester,
    ) async {
      await _pump(tester, _repository(), child: const WeekBalanceModeChoice());

      final rows = {
        WeekBalanceMode.off: ('Aus', 'Jeder Tag steht für sich.'),
        WeekBalanceMode.show: (
          'Anzeigen',
          'Zeigt die Woche. Dein Tagesbudget bleibt gleich.',
        ),
        WeekBalanceMode.carryover: (
          'Mit Übertrag',
          'Gleicht die Woche aus, höchstens 350 kcal pro Tag.',
        ),
      };
      for (final MapEntry(key: mode, value: (label, line)) in rows.entries) {
        expect(
          find.descendant(of: _option(mode), matching: find.text(label)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: _option(mode), matching: find.text(line)),
          findsOneWidget,
        );
      }
      expect(find.byKey(WeekBalanceModeKeys.selected), findsOneWidget);
      expect(_selected(), WeekBalanceMode.show);
    });

    testWidgets('K35: the line names 20 % of a goal of 1.600', (tester) async {
      await _pump(
        tester,
        _repository(goal: 1600),
        child: const WeekBalanceModeChoice(),
      );

      expect(
        find.text('Gleicht die Woche aus, höchstens 320 kcal pro Tag.'),
        findsOneWidget,
      );
    });

    testWidgets('a tap stores the mode and reports the pick', (tester) async {
      final repository = _repository();
      var picks = 0;
      await _pump(
        tester,
        repository,
        child: WeekBalanceModeChoice(onPicked: () => picks += 1),
      );

      await tester.tap(_option(WeekBalanceMode.carryover));
      await tester.pumpAndSettle();

      expect(
        (await repository.readSettings()).weekBalanceMode,
        WeekBalanceMode.carryover,
      );
      expect(picks, 1);
      expect(_selected(), WeekBalanceMode.carryover);
    });

    testWidgets('a failed save keeps the mode and reports no pick', (
      tester,
    ) async {
      final repository = _repository()..saveShouldFail = true;
      var picks = 0;
      await _pump(
        tester,
        repository,
        child: WeekBalanceModeChoice(onPicked: () => picks += 1),
      );

      await tester.tap(_option(WeekBalanceMode.off));
      await tester.pumpAndSettle();

      expect(picks, 0);
      expect(_selected(), WeekBalanceMode.show);
      expect(
        (await repository.readSettings()).weekBalanceMode,
        WeekBalanceMode.show,
      );
    });

    testWidgets('a failed save says so in a snack bar', (tester) async {
      final repository = _repository()..saveShouldFail = true;
      await _pump(tester, repository, child: const WeekBalanceModeChoice());

      await tester.tap(_option(WeekBalanceMode.carryover));
      await tester.pumpAndSettle();

      expect(
        find.text('Wochenzielbalance konnte nicht geändert werden.'),
        findsOneWidget,
      );
      expect(_selected(), WeekBalanceMode.show);
    });

    testWidgets('settings that fail to load show the load error and no '
        'option', (tester) async {
      final repository = _repository();
      await _pump(
        tester,
        _FailingSettingsRepository(repository),
        child: const WeekBalanceModeChoice(),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text(
          'Dein Ziel konnte nicht geladen werden. Prüfe deine Verbindung.',
        ),
        findsOneWidget,
      );
      for (final mode in WeekBalanceMode.values) {
        expect(_option(mode), findsNothing, reason: mode.name);
      }
    });

    testWidgets('K35: the limit follows the goal of today with its TDEE '
        'offset, not the stored goal', (tester) async {
      // Stored 2.200 (limit 350); today's TDEE takes 600 off: 1.600 → 320.
      await _pump(
        tester,
        _repository(),
        child: const WeekBalanceModeChoice(),
        overrides: [
          goalTdeeOffsetsByDayProvider.overrideWith((ref) async {
            final settings = await ref.watch(
              calorieGoalControllerProvider.future,
            );
            return GoalTdeeOffsets(
              settings: settings,
              byDay: const {'2026-11-19': -600},
            );
          }),
        ],
      );

      expect(
        find.text('Gleicht die Woche aus, höchstens 320 kcal pro Tag.'),
        findsOneWidget,
      );
    });

    testWidgets('the carryover option has no line while the budget settings '
        'load', (tester) async {
      await _pump(
        tester,
        _repository(),
        child: const WeekBalanceModeChoice(),
        overrides: [
          calorieBudgetSettingsProvider.overrideWith(
            (ref) => Completer<CalorieGoalSettings>().future,
          ),
        ],
      );

      _expectCarryoverWithoutLine();
    });

    testWidgets('the carryover option has no line when the budget settings '
        'fail', (tester) async {
      await _pump(
        tester,
        _repository(),
        child: const WeekBalanceModeChoice(),
        overrides: [
          calorieBudgetSettingsProvider.overrideWith(
            (ref) async => throw StateError('budget failed'),
          ),
        ],
      );

      expect(tester.takeException(), isNull);
      _expectCarryoverWithoutLine();
    });
  });
}

/// The carryover option shows its label and no line, and the other options
/// keep theirs.
void _expectCarryoverWithoutLine() {
  final carryover = _option(WeekBalanceMode.carryover);
  expect(
    find.descendant(of: carryover, matching: find.text('Mit Übertrag')),
    findsOneWidget,
  );
  expect(
    find.descendant(of: carryover, matching: find.textContaining('kcal')),
    findsNothing,
  );
  expect(
    find.descendant(
      of: carryover,
      matching: find.textContaining('Gleicht die Woche aus'),
    ),
    findsNothing,
  );
  expect(
    find.descendant(
      of: _option(WeekBalanceMode.show),
      matching: find.text('Zeigt die Woche. Dein Tagesbudget bleibt gleich.'),
    ),
    findsOneWidget,
  );
}

/// Settings whose stream fails.
class _FailingSettingsRepository implements CalorieSettingsRepository {
  new(this._inner);

  final FakeCalorieSettingsRepository _inner;

  @override
  Stream<CalorieGoalSettings> watchSettings() =>
      Stream<CalorieGoalSettings>.error(StateError('settings failed'));

  @override
  Future<CalorieGoalSettings> readSettings() => _inner.readSettings();

  @override
  Future<void> saveSettings(CalorieGoalSettings settings) =>
      _inner.saveSettings(settings);
}
