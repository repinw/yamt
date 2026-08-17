import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import 'package:yamt/features/activity/application/diary_steps_summary_provider.dart';
import 'package:yamt/features/activity/presentation/widgets/diary_workouts_card.dart';
import 'package:yamt/features/calories/provider/calorie_resolved_goal_provider.dart';
import 'package:yamt/features/health/domain/diary_activity_summary.dart';
import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_workout_session.dart';
import 'package:yamt/l10n/app_localizations.dart';

void main() {
  final selectedDay = DateTime(2026, 4, 27);

  testWidgets('renders tracked workout sessions', (tester) async {
    await _pumpWorkoutsCard(
      tester,
      selectedDay: selectedDay,
      summary: _summary(selectedDay, [
        _workout(
          selectedDay,
          activityLabel: 'Cycling',
          durationMinutes: 42,
          totalCalories: 320,
          sourceName: 'Health Connect',
        ),
      ]),
    );

    expect(find.text('WORKOUTS'), findsOneWidget);
    expect(find.text('Cycling'), findsOneWidget);
    expect(find.textContaining('Health Connect'), findsOneWidget);
    expect(find.text('42 min'), findsOneWidget);
    expect(find.text('320 kcal'), findsOneWidget);
  });

  testWidgets('renders empty workouts state', (tester) async {
    await _pumpWorkoutsCard(
      tester,
      selectedDay: selectedDay,
      summary: _summary(selectedDay, const []),
    );

    expect(find.text('WORKOUTS'), findsOneWidget);
    expect(find.text('No workouts'), findsOneWidget);
  });

  testWidgets('shows retry and reloads after workouts load error', (
    tester,
  ) async {
    var shouldFail = true;
    await _pumpDiaryWidget(
      tester,
      DiaryWorkoutsCard(selectedDay: selectedDay),
      overrides: [
        diaryStepsSummaryProvider(selectedDay).overrideWith((ref) async {
          if (shouldFail) {
            throw StateError('load failed');
          }
          return _summary(selectedDay, [
            _workout(
              selectedDay,
              activityLabel: 'Cycling',
              durationMinutes: 42,
              totalCalories: 320,
              sourceName: 'Health Connect',
            ),
          ]);
        }),
      ],
    );

    expect(find.text('Workouts could not be loaded'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Workouts could not be loaded'), findsNothing);
    expect(find.text('Cycling'), findsOneWidget);
  });

  testWidgets(
    'renders baseline progress banner when activity is below baseline',
    (tester) async {
      await _pumpDiaryWidget(
        tester,
        DiaryWorkoutsCard(selectedDay: selectedDay),
        overrides: [
          diaryStepsSummaryProvider(
            selectedDay,
          ).overrideWith((ref) async => _summary(selectedDay, [
                _workout(
                  selectedDay,
                  activityLabel: 'Running',
                  durationMinutes: 30,
                  totalCalories: 200,
                  sourceName: 'Health Connect',
                ),
              ])),
          resolvedCalorieGoalForDayProvider(selectedDay).overrideWith(
            (ref) async => ResolvedCalorieGoalData(
              day: selectedDay,
              storedGoalKcal: 2000,
              goalKcal: 2000,
              activityDeltaKcal: 0,
              activityComparisonKcal: -150,
              correctedActivityKcal: 200,
              activityCapKcal: 200,
              todayActiveKcal: 200,
              expectedActivityKcal: 400,
              lastWeekAverageActiveKcal: 300,
              usedLearnedTdee: false,
              usesPreLearningActivityBonus: false,
              wasClampedToMinimum: false,
              isActivityTrackingActive: true,
            ),
          ),
        ],
      );

      expect(
        find.text(
          '200 / 400 kcal baseline activity • 200 kcal to bonus',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'renders extra sport bonus banner when activity exceeds baseline',
    (tester) async {
      await _pumpDiaryWidget(
        tester,
        DiaryWorkoutsCard(selectedDay: selectedDay),
        overrides: [
          diaryStepsSummaryProvider(
            selectedDay,
          ).overrideWith((ref) async => _summary(selectedDay, [
                _workout(
                  selectedDay,
                  activityLabel: 'Running',
                  durationMinutes: 60,
                  totalCalories: 600,
                  sourceName: 'Health Connect',
                ),
              ])),
          resolvedCalorieGoalForDayProvider(selectedDay).overrideWith(
            (ref) async => ResolvedCalorieGoalData(
              day: selectedDay,
              storedGoalKcal: 2000,
              goalKcal: 2200,
              activityDeltaKcal: 200,
              activityComparisonKcal: 200,
              correctedActivityKcal: 600,
              activityCapKcal: 600,
              todayActiveKcal: 600,
              expectedActivityKcal: 400,
              lastWeekAverageActiveKcal: 300,
              usedLearnedTdee: false,
              usesPreLearningActivityBonus: true,
              wasClampedToMinimum: false,
              isActivityTrackingActive: true,
            ),
          ),
        ],
      );

      expect(
        find.text(
          '+200 kcal extra sport bonus credited to daily goal!',
        ),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpWorkoutsCard(
  WidgetTester tester, {
  required DateTime selectedDay,
  required DiaryActivitySummary summary,
}) async {
  await _pumpDiaryWidget(
    tester,
    DiaryWorkoutsCard(selectedDay: selectedDay),
    overrides: [
      diaryStepsSummaryProvider(
        selectedDay,
      ).overrideWith((ref) async => summary),
    ],
  );
}

DiaryActivitySummary _summary(
  DateTime day,
  List<HealthWorkoutSession> workouts,
) {
  return DiaryActivitySummary(
    day: day,
    stepGoal: 10000,
    accessState: HealthDataAccessState.ready,
    totalSteps: 6500,
    stepsDuringWorkouts: 1200,
    stepsOutsideWorkouts: 5300,
    workouts: workouts,
  );
}

HealthWorkoutSession _workout(
  DateTime day, {
  required String activityLabel,
  required int durationMinutes,
  required int totalCalories,
  required String sourceName,
}) {
  return HealthWorkoutSession(
    id: activityLabel,
    start: day.add(const Duration(hours: 7)),
    endExclusive: day.add(Duration(hours: 7, minutes: durationMinutes)),
    durationMinutes: durationMinutes.toDouble(),
    activityLabel: activityLabel,
    sourceName: sourceName,
    totalCalories: totalCalories,
    totalSteps: 1200,
  );
}

Future<void> _pumpDiaryWidget(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
