import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/onboarding/application/'
    'calorie_goal_onboarding_catch_up_placeholder_writer.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_start.dart';

import '../../calories/support/fake_calories_repositories.dart';

void main() {
  group('CalorieGoalOnboardingCatchUpPlaceholderWriter', () {
    test('rolls back placeholders when a later save fails', () async {
      var nextId = 0;
      final logRepository = _FailingCalorieLogRepository(failOnSaveAttempt: 2);
      addTearDown(logRepository.dispose);
      final writer = CalorieGoalOnboardingCatchUpPlaceholderWriter(
        logRepository: logRepository,
        isMounted: () => true,
        idGenerator: () => 'placeholder-${++nextId}',
      );

      final saved = await writer.writePlaceholders(
        now: DateTime(2026, 4, 22, 18),
        dailyGoalKcal: 2400,
        estimate: CalorieGoalOnboardingCatchUpEstimate.high,
        placeholderName: 'Estimated meal',
      );

      expect(saved, isFalse);
      expect(logRepository.entries, isEmpty);
      expect(logRepository.deletedIds, <String>['placeholder-1']);
    });

    test('rolls back saved placeholder when unmounted after save', () async {
      var mounted = true;
      var nextId = 0;
      final logRepository = _AfterSaveCallbackCalorieLogRepository(
        onSaved: () {
          mounted = false;
        },
      );
      addTearDown(logRepository.dispose);
      final writer = CalorieGoalOnboardingCatchUpPlaceholderWriter(
        logRepository: logRepository,
        isMounted: () => mounted,
        idGenerator: () => 'placeholder-${++nextId}',
      );

      final saved = await writer.writePlaceholders(
        now: DateTime(2026, 4, 22, 18),
        dailyGoalKcal: 2400,
        estimate: CalorieGoalOnboardingCatchUpEstimate.high,
        placeholderName: 'Estimated meal',
      );

      expect(saved, isFalse);
      expect(logRepository.entries, isEmpty);
      expect(logRepository.deletedIds, <String>['placeholder-1']);
    });
  });
}

class _FailingCalorieLogRepository extends FakeCalorieLogRepository {
  _FailingCalorieLogRepository({required this.failOnSaveAttempt});

  final int failOnSaveAttempt;
  final deletedIds = <String>[];
  int _saveAttemptCount = 0;

  @override
  Future<bool> saveEntryForCurrentUser(CalorieEntry entry) async {
    _saveAttemptCount += 1;
    if (_saveAttemptCount == failOnSaveAttempt) {
      return false;
    }
    return super.saveEntryForCurrentUser(entry);
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    deletedIds.add(entryId);
    return super.deleteEntry(entryId);
  }
}

class _AfterSaveCallbackCalorieLogRepository extends FakeCalorieLogRepository {
  _AfterSaveCallbackCalorieLogRepository({required this.onSaved});

  final void Function() onSaved;
  final deletedIds = <String>[];

  @override
  Future<bool> saveEntryForCurrentUser(CalorieEntry entry) async {
    final saved = await super.saveEntryForCurrentUser(entry);
    if (saved) {
      onSaved();
    }
    return saved;
  }

  @override
  Future<bool> deleteEntry(String entryId) async {
    deletedIds.add(entryId);
    return super.deleteEntry(entryId);
  }
}
