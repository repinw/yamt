import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/l10n/app_localizations_delegates.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin_plan.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_sheet/diary_weekly_checkin_sheet_result.dart';
import 'package:yamt/l10n/app_localizations.dart';

final _today = DateTime(2026, 4, 20);

void main() {
  testWidgets('ready check-in walks the three steps and returns apply', (
    tester,
  ) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _scoped(_App(checkInData: _readyData(), onResult: results.add)),
    );
    await _openSheet(tester);

    expect(find.text('Week done'), findsOneWidget);
    expect(
      find.byKey(DiaryWeeklyCheckInSheetKeys.useMeasuredChoice),
      findsOneWidget,
    );

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.text('When do you train?'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(DiaryWeeklyCheckInSheetKeys.trainingDay(1)),
    );
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.text('Daily goal on average'.toUpperCase()), findsOneWidget);
    expect(find.text('measured'), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.startWeekButton));
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single!.action, DiaryWeeklyCheckInSheetAction.apply);
    expect(results.single!.training!.trainingDays, hasLength(4));
  });

  testWidgets('past days and pause days keep their type and say why', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _scoped(
        _App(checkInData: _readyData(), onResult: results.add),
        plan: _latePlan(),
      ),
    );
    await _openSheet(tester);
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();

    expect(
      find.byKey(DiaryWeeklyCheckInSheetKeys.fixedDaysHint),
      findsOneWidget,
    );
    final pastDay = find.byKey(DiaryWeeklyCheckInSheetKeys.trainingDay(0));
    final pauseDay = find.byKey(DiaryWeeklyCheckInSheetKeys.trainingDay(1));
    expect(
      tester.getSemantics(pastDay),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );

    await _tapVisible(tester, pastDay);
    await tester.pumpAndSettle();
    await _tapVisible(tester, pauseDay);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.startWeekButton));
    await tester.pumpAndSettle();

    final plan = _latePlan();
    expect(results.single!.training!.trainingDays, plan.suggestedTrainingDays);
    expect(results.single!.training!.runDay, plan.nextRunDays.first);
    semantics.dispose();
  });

  testWidgets('keeping the previous TDEE returns reject', (tester) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _scoped(_App(checkInData: _readyData(), onResult: results.add)),
    );
    await _openSheet(tester);

    await _tapVisible(
      tester,
      find.byKey(DiaryWeeklyCheckInSheetKeys.keepPreviousChoice),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    await _tapVisible(
      tester,
      find.byKey(DiaryWeeklyCheckInSheetKeys.noSessionButton),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton));
    await tester.pumpAndSettle();
    expect(find.text('previous'), findsOneWidget);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.startWeekButton));
    await tester.pumpAndSettle();

    expect(results.single!.action, DiaryWeeklyCheckInSheetAction.reject);
    expect(results.single!.training!.trainingDays, isEmpty);
  });

  testWidgets('later and change goal close the sheet with their action', (
    tester,
  ) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _scoped(_App(checkInData: _readyData(), onResult: results.add)),
    );

    await _openSheet(tester);
    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.laterButton));
    await tester.pumpAndSettle();

    await _openSheet(tester);
    await _tapVisible(
      tester,
      find.byKey(DiaryWeeklyCheckInSheetKeys.changeGoalButton),
    );
    await tester.pumpAndSettle();

    expect(results.map((result) => result?.action), [
      DiaryWeeklyCheckInSheetAction.later,
      DiaryWeeklyCheckInSheetAction.newGoal,
    ]);
    expect(results.map((result) => result?.training), [null, null]);
  });

  testWidgets('blocked check-in offers the missing weight and later', (
    tester,
  ) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _scoped(
        _App(
          checkInData: calorieWeeklyCheckInDemoData(
            today: _today,
            blocked: true,
          ),
          onResult: results.add,
        ),
      ),
    );
    await _openSheet(tester);

    expect(find.text('Check-in needs data'), findsOneWidget);
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.nextButton), findsNothing);

    await tester.tap(
      find.byKey(DiaryWeeklyCheckInSheetKeys.trackMissingWeightButton),
    );
    await tester.pumpAndSettle();

    expect(
      results.single!.action,
      DiaryWeeklyCheckInSheetAction.trackMissingWeight,
    );
  });

  testWidgets('reached goal only offers a new goal and cannot be dismissed', (
    tester,
  ) async {
    final results = <DiaryWeeklyCheckInSheetResult?>[];
    await tester.pumpWidget(
      _scoped(
        _App(
          checkInData: _readyData(),
          onResult: results.add,
          goalReached: true,
        ),
      ),
    );
    await _openSheet(tester);

    expect(find.text('Congratulations!'), findsOneWidget);
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.laterButton), findsNothing);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byKey(DiaryWeeklyCheckInSheetKeys.sheet), findsOneWidget);
    expect(results, isEmpty);

    await tester.tap(find.byKey(DiaryWeeklyCheckInSheetKeys.newGoalButton));
    await tester.pumpAndSettle();

    expect(results.single!.action, DiaryWeeklyCheckInSheetAction.newGoal);
  });
}

CalorieWeeklyCheckInData _readyData() =>
    calorieWeeklyCheckInDemoData(today: _today);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

Future<void> _openSheet(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(1080, 2400)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.tap(find.byKey(_openSheetButtonKey));
  await tester.pumpAndSettle();
}

CalorieWeeklyCheckInPlan _demoPlan() => calorieWeeklyCheckInDemoPlan(
  today: _today,
  macroSettings: const MacroGoalSettings(),
  profile: null,
);

/// The demo plan of a late check-in: the first day is past, the second a
/// pause day.
CalorieWeeklyCheckInPlan _latePlan() {
  final plan = _demoPlan();
  final days = plan.nextRunDays;
  return CalorieWeeklyCheckInPlan(
    reviewedRunNumber: plan.reviewedRunNumber,
    nextRunNumber: plan.nextRunNumber,
    reviewedDays: plan.reviewedDays,
    previousTrainingDayCount: plan.previousTrainingDayCount,
    nextRunDays: days,
    suggestedTrainingDays: plan.suggestedTrainingDays,
    pauseDays: {days[1]},
    pastDays: {days[0]},
    hasWeeklyTrainingSchedule: plan.hasWeeklyTrainingSchedule,
    sessionKcal: plan.sessionKcal,
    previousTdeeKcal: plan.previousTdeeKcal,
    previousGoalKcal: plan.previousGoalKcal,
    measurement: plan.measurement,
    progress: plan.progress,
    profile: plan.profile,
    macroSettings: plan.macroSettings,
    previousMacroWeightKg: plan.previousMacroWeightKg,
    newMacroWeightKg: plan.newMacroWeightKg,
    isLosingWeight: plan.isLosingWeight,
  );
}

Widget _scoped(Widget app, {CalorieWeeklyCheckInPlan? plan}) {
  final container = ProviderContainer(
    overrides: [
      diaryWeeklyCheckInPlanProvider.overrideWith(
        (ref) async => plan ?? _demoPlan(),
      ),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(container: container, child: app);
}

const _openSheetButtonKey = ValueKey<String>('open-sheet');

class _App extends StatelessWidget {
  const new({
    required this.checkInData,
    required this.onResult,
    this.goalReached = false,
  });

  final CalorieWeeklyCheckInData checkInData;
  final ValueChanged<DiaryWeeklyCheckInSheetResult?> onResult;
  final bool goalReached;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              key: _openSheetButtonKey,
              onPressed: () async {
                onResult(
                  await showDiaryWeeklyCheckInSheet(
                    context,
                    checkInData: checkInData,
                    goalReached: goalReached,
                  ),
                );
              },
              child: const Text('Open sheet'),
            );
          },
        ),
      ),
    );
  }
}
