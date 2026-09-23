import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/calories/domain/calorie_goal_transition_helpers.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/onboarding/application/'
    'calorie_goal_onboarding_finish_flow.dart';

import '../../calories/support/fake_calories_repositories.dart';

const _profile = CalorieCalculatorProfile.defaults();

class _Harness {
  const new({
    required this.container,
    required this.settingsRepository,
    required this.runStateRepository,
  });

  final ProviderContainer container;
  final FakeCalorieSettingsRepository settingsRepository;
  final _FakeBurnWeekRunStateRepository runStateRepository;
}

Future<_Harness> _buildHarness() async {
  final settingsRepository = FakeCalorieSettingsRepository();
  final logRepository = FakeCalorieLogRepository();
  final runStateRepository = _FakeBurnWeekRunStateRepository(
    const BurnWeekRunState.initial(),
  );
  final container = ProviderContainer(
    overrides: [
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
      calorieLogRepositoryProvider.overrideWithValue(logRepository),
      burnWeekRunStateRepositoryProvider.overrideWithValue(runStateRepository),
    ],
  );
  addTearDown(container.dispose);
  addTearDown(settingsRepository.dispose);

  await container.read(calorieGoalControllerProvider.future);
  await container.read(burnWeekRunControllerProvider.future);

  return _Harness(
    container: container,
    settingsRepository: settingsRepository,
    runStateRepository: runStateRepository,
  );
}

Future<bool> _saveOnboardingGoal(
  _Harness harness,
  DateTime today, {
  DateTime? startDate,
}) {
  return harness.container
      .read(calorieGoalOnboardingFinishFlowProvider)
      .saveGoal(
        CalorieGoalOnboardingFinishRequest(
          profile: _profile,
          today: today,
          startDate: startDate ?? today,
        ),
      );
}

void main() {
  group('CalorieGoalOnboardingFinishFlow', () {
    test('saves the goal starting today', () async {
      final harness = await _buildHarness();
      final today = DateTime(2026, 4, 22, 12);

      final saved = await _saveOnboardingGoal(harness, today);

      expect(saved, isTrue);
      final settings = await harness.settingsRepository.readSettings();
      final goalEntry = settings.goalHistory.single;
      expect(goalEntry.effectiveDate, normalizeDiaryDay(today));
    });

    test('counts today for learning when the user starts today', () async {
      final harness = await _buildHarness();
      final today = DateTime(2026, 4, 22, 18);

      await _saveOnboardingGoal(harness, today);

      final settings = await harness.settingsRepository.readSettings();
      final goalEntry = settings.goalHistory.single;
      expect(goalEntry.effectiveCountingStartDate, normalizeDiaryDay(today));
      expect(goalEntryCountsStartDay(goalEntry), isTrue);
    });

    test('starts counting on a later start day', () async {
      final harness = await _buildHarness();
      final today = DateTime(2026, 4, 22, 18);
      final startDate = DateTime(2026, 4, 23);

      final saved = await _saveOnboardingGoal(
        harness,
        today,
        startDate: startDate,
      );

      expect(saved, isTrue);
      final settings = await harness.settingsRepository.readSettings();
      final goalEntry = settings.goalHistory.single;
      expect(goalEntry.effectiveCountingStartDate, startDate);
      expect(goalEntryCountsStartDay(goalEntry), isTrue);
      expect(settings.nextGoalStartAfterDay(today), startDate);
    });

    test('leaves burn week to live sync for a later start day', () async {
      final harness = await _buildHarness();

      await _saveOnboardingGoal(
        harness,
        DateTime(2026, 4, 22, 18),
        startDate: DateTime(2026, 4, 23),
      );

      expect(harness.runStateRepository.state.currentWeekStartDayKey, isNull);
    });

    test('bootstraps burn week from today', () async {
      final harness = await _buildHarness();
      final today = DateTime(2026, 4, 22, 12);

      await _saveOnboardingGoal(harness, today);

      final runState = harness.runStateRepository.state;
      expect(
        runState.currentWeekStartDayKey,
        diaryDayKey(normalizeDiaryDay(today)),
      );
      expect(runState.runWeekNumber, burnWeekLearningRunWeekNumber);
      expect(runState.heartCreditKcal, 0);
    });

    test(
      'reports failure and skips burn week when the goal save fails',
      () async {
        final harness = await _buildHarness();
        harness.settingsRepository.saveShouldFail = true;

        final saved = await _saveOnboardingGoal(harness, DateTime(2026, 4, 22));

        expect(saved, isFalse);
        expect(harness.runStateRepository.state.currentWeekStartDayKey, isNull);
      },
    );
  });
}

class _FakeBurnWeekRunStateRepository implements BurnWeekRunStateRepository {
  new(this.state);

  BurnWeekRunState state;

  @override
  Future<BurnWeekRunState> readState() async => state;

  @override
  Future<bool> saveState(BurnWeekRunState nextState) async {
    state = nextState;
    return true;
  }
}
