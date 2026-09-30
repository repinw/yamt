import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_weekly_checkin_sheet_controller.dart';

final _today = DateTime(2026, 9, 30);
final _windowStart = DateTime(2026, 9, 23);

DiaryWeeklyCheckInPlan _plan({bool measured = true}) {
  final plan = calorieWeeklyCheckInDemoPlan(
    today: _today,
    macroSettings: const MacroGoalSettings(),
    profile: null,
  );
  if (measured) {
    return plan;
  }
  return DiaryWeeklyCheckInPlan(
    reviewedRunNumber: plan.reviewedRunNumber,
    nextRunNumber: plan.nextRunNumber,
    reviewedDays: plan.reviewedDays,
    previousTrainingDayCount: plan.previousTrainingDayCount,
    nextRunDays: plan.nextRunDays,
    suggestedTrainingDays: plan.suggestedTrainingDays,
    pauseDays: {plan.nextRunDays[1]},
    pastDays: {plan.nextRunDays[0]},
    hasWeeklyTrainingSchedule: true,
    sessionKcal: plan.sessionKcal,
    previousTdeeKcal: plan.previousTdeeKcal,
    previousGoalKcal: plan.previousGoalKcal,
    measurement: null,
    progress: plan.progress,
    profile: null,
    macroSettings: plan.macroSettings,
    previousMacroWeightKg: plan.previousMacroWeightKg,
    newMacroWeightKg: plan.newMacroWeightKg,
    isLosingWeight: true,
  );
}

Future<
  ({
    ProviderContainer container,
    DiaryWeeklyCheckInSheetControllerProvider provider,
  })
>
_start({DateTime? windowStart, bool measured = true}) async {
  final plan = _plan(measured: measured);
  final container = ProviderContainer(
    overrides: [
      diaryWeeklyCheckInPlanProvider.overrideWith((ref) async => plan),
    ],
  );
  addTearDown(container.dispose);
  final provider = diaryWeeklyCheckInSheetControllerProvider(
    windowStart: windowStart ?? _windowStart,
  );
  final subscription = container.listen(provider, (_, _) {});
  addTearDown(subscription.close);
  await container.read(provider.future);
  return (container: container, provider: provider);
}

void main() {
  test(
    'starts on the review with the measured TDEE and the suggestion',
    () async {
      final (:container, :provider) = await _start();

      final state = container.read(provider).value!;
      expect(state.step, DiaryWeeklyCheckInStep.review);
      expect(state.useMeasured, isTrue);
      expect(state.trainingDays, state.plan.suggestedTrainingDays);
    },
  );

  test('toggles, resets, and clears the training days', () async {
    final (:container, :provider) = await _start();
    final controller = container.read(provider.notifier);
    final days = container.read(provider).value!.plan.nextRunDays;

    controller.toggleTrainingDay(days[1]);
    expect(container.read(provider).value!.trainingDays, contains(days[1]));
    controller.toggleTrainingDay(days[0]);
    expect(
      container.read(provider).value!.trainingDays,
      isNot(contains(days[0])),
    );

    controller.clearTrainingDays();
    expect(container.read(provider).value!.trainingDays, isEmpty);
    controller.resetTrainingDays();
    expect(container.read(provider).value!.trainingDays, hasLength(3));
  });

  test(
    'without a measurement it keeps the previous TDEE and pause days',
    () async {
      final (:container, :provider) = await _start(measured: false);
      final controller = container.read(provider.notifier);
      final pauseDay = container.read(provider).value!.plan.nextRunDays[1];

      controller
        ..setUseMeasured(useMeasured: true)
        ..toggleTrainingDay(pauseDay);

      final state = container.read(provider).value!;
      expect(state.useMeasured, isFalse);
      expect(state.trainingDays, isNot(contains(pauseDay)));
      expect(state.targets.isMeasured, isFalse);
    },
  );

  test('a reload of the same window keeps the step and the choices', () async {
    final (:container, :provider) = await _start();
    container.read(provider.notifier)
      ..setUseMeasured(useMeasured: false)
      ..goTo(DiaryWeeklyCheckInStep.targets)
      ..clearTrainingDays();

    container.invalidate(diaryWeeklyCheckInPlanProvider);
    await container.read(provider.future);

    final state = container.read(provider).value!;
    expect(state.step, DiaryWeeklyCheckInStep.targets);
    expect(state.useMeasured, isFalse);
    expect(state.trainingDays, isEmpty);
  });

  test('a plan of another window gives no state', () async {
    final (:container, :provider) = await _start(
      windowStart: DateTime(2026, 9, 16),
    );

    expect(container.read(provider).value, isNull);
  });
}
