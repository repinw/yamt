// The choice of the week balance mode and the week card's menu (#911):
// K1, K2, K3 and K35 of lib/features/diary/CRITERIA.md.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/week_balance_mode.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/diary_week_card_menu.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_week_card/week_balance_mode_choice.dart';
import 'package:yamt/l10n/app_localizations.dart';

import '../../../../calories/support/fake_calories_repositories.dart';

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
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 11, 19, 10)),
        calorieSettingsRepositoryProvider.overrideWithValue(repository),
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
    find.byKey(DiaryWeekCardKeys.modeOption(mode));

/// The mode whose option holds the selected mark.
WeekBalanceMode? _selected() {
  for (final mode in WeekBalanceMode.values) {
    final mark = find.descendant(
      of: _option(mode),
      matching: find.byKey(DiaryWeekCardKeys.modeSelected),
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
      expect(find.byKey(DiaryWeekCardKeys.modeSelected), findsOneWidget);
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

    testWidgets('settings that fail to load throw nothing', (tester) async {
      final repository = _repository();
      await _pump(
        tester,
        _FailingSettingsRepository(repository),
        child: const WeekBalanceModeChoice(),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('the menu of the week card', () {
    Widget opener() => Builder(
      builder: (context) => TextButton(
        onPressed: () => unawaited(showDiaryWeekCardMenu(context)),
        child: const Text('open'),
      ),
    );

    testWidgets('K1/K2: heading, the choice and where to change it later', (
      tester,
    ) async {
      await _pump(tester, _repository(), child: opener());

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final menu = find.byKey(DiaryWeekCardKeys.menu);
      expect(menu, findsOneWidget);
      expect(
        find.descendant(of: menu, matching: find.text('Wochenzielbalance')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: menu,
          matching: find.text('Später ändern: in den Einstellungen.'),
        ),
        findsOneWidget,
      );
      for (final mode in WeekBalanceMode.values) {
        expect(
          find.descendant(of: menu, matching: _option(mode)),
          findsOneWidget,
        );
      }
      // No separate switch for "Übertrag" or "anzeigen" (K2).
      expect(
        find.descendant(of: menu, matching: find.byType(Switch)),
        findsNothing,
      );
    });

    testWidgets('K3: a pick closes the menu', (tester) async {
      final repository = _repository();
      await _pump(tester, repository, child: opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(_option(WeekBalanceMode.off));
      await tester.pumpAndSettle();

      expect(find.byKey(DiaryWeekCardKeys.menu), findsNothing);
      expect(
        (await repository.readSettings()).weekBalanceMode,
        WeekBalanceMode.off,
      );
    });
  });
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
