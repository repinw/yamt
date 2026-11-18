import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/calorie_balance_cycle.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_week_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

class _RecordingCalorieGoalController extends CalorieGoalController {
  new(this.settings);

  final CalorieGoalSettings settings;
  final calls = <String>[];

  @override
  CalorieGoalSettings build() => settings;

  @override
  Future<bool> setPauseDay({
    required DateTime day,
    required bool isPause,
  }) async {
    calls.add('pause:$isPause');
    return true;
  }

  @override
  Future<bool> toggleTrainingDay(DateTime day) async {
    calls.add('toggleTraining');
    return true;
  }
}

/// Monday 2026-04-27 is a training day, Tuesday a pause day, and Wednesday
/// a normal day.
final _monday = DateTime(2026, 4, 27);

Future<_RecordingCalorieGoalController> _pumpStrip(
  WidgetTester tester, {
  int dayCount = calorieGoalRunLengthDays,
  List<int> trainingWeekdays = const [DateTime.monday],
}) async {
  final controller = _RecordingCalorieGoalController(
    const CalorieGoalSettings.empty().copyWith(
      dailyKcalGoal: 2200,
      trainingWeekdays: trainingWeekdays,
      trainingDayKcalOffset: 150,
      pauseDayKeys: [localDayKey(addLocalDays(_monday, 1))],
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [calorieGoalControllerProvider.overrideWith(() => controller)],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DiaryBudgetWeekStrip(
            weekStart: _monday,
            dayCount: dayCount,
            selectedDay: _monday,
            today: _monday,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  testWidgets('a tap turns a normal day into a training day', (tester) async {
    final controller = await _pumpStrip(tester);

    await tester.tap(find.byKey(DiaryBudgetCardKeys.weekDay(2)));
    await tester.pumpAndSettle();

    expect(controller.calls, ['toggleTraining']);
  });

  testWidgets('a tap turns a training day back into a normal day (#921)', (
    tester,
  ) async {
    final controller = await _pumpStrip(tester);

    await tester.tap(find.byKey(DiaryBudgetCardKeys.weekDay(0)));
    await tester.pumpAndSettle();

    expect(controller.calls, ['toggleTraining']);
  });

  testWidgets('a pause day shows but a tap leaves it alone (#921)', (
    tester,
  ) async {
    final controller = await _pumpStrip(tester);

    expect(
      find.bySemanticsLabel('Tuesday: Pause day, set with the pause button'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(DiaryBudgetCardKeys.weekDay(1)));
    await tester.pumpAndSettle();

    expect(controller.calls, isEmpty);
  });

  group('a run cut short to three days (K51)', () {
    // Monday and Thursday are training days; Thursday lies after the cut.
    const trainingWeekdays = [DateTime.monday, DateTime.thursday];

    testWidgets('shows only its three days and counts only their training '
        'days', (tester) async {
      await _pumpStrip(tester, dayCount: 3, trainingWeekdays: trainingWeekdays);

      for (var i = 0; i < 3; i++) {
        expect(find.byKey(DiaryBudgetCardKeys.weekDay(i)), findsOneWidget);
      }
      for (var i = 3; i < calorieGoalRunLengthDays; i++) {
        expect(
          find.byKey(DiaryBudgetCardKeys.weekDay(i)),
          findsNothing,
          reason: 'day $i',
        );
      }
      expect(
        find.descendant(
          of: find.byKey(DiaryBudgetCardKeys.weekStrip),
          matching: find.text('1 training day'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the full run counts the training day after the cut', (
      tester,
    ) async {
      await _pumpStrip(tester, trainingWeekdays: trainingWeekdays);

      expect(find.text('2 training days'), findsOneWidget);
    });

    testWidgets('no day after the cut can be tapped', (tester) async {
      final controller = await _pumpStrip(
        tester,
        dayCount: 3,
        trainingWeekdays: trainingWeekdays,
      );

      // The room where Thursday to Sunday would stand.
      final lastDay = tester.getRect(
        find.byKey(DiaryBudgetCardKeys.weekDay(2)),
      );
      final strip = tester.getRect(find.byKey(DiaryBudgetCardKeys.weekStrip));
      for (var x = lastDay.right + 4; x < strip.right - 4; x += 8) {
        await tester.tapAt(Offset(x, lastDay.center.dy));
      }
      await tester.pumpAndSettle();

      expect(controller.calls, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
