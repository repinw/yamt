import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
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

Future<_RecordingCalorieGoalController> _pumpStrip(WidgetTester tester) async {
  final controller = _RecordingCalorieGoalController(
    const CalorieGoalSettings.empty().copyWith(
      dailyKcalGoal: 2200,
      trainingWeekdays: const [DateTime.monday],
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
}
