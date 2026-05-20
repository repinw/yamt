import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_calculator.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

class _FakeCalorieSettingsUserSession implements CalorieSettingsUserSession {
  _FakeCalorieSettingsUserSession({this.currentUserId});

  @override
  final String? currentUserId;
}

void main() {
  test('setDailyGoal persists and readSettings returns value', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieSettingsRepository(
      session: _FakeCalorieSettingsUserSession(currentUserId: 'user-1'),
      firestore: firestore,
    );

    final saved = await repository.setDailyGoal(2400);
    final settings = await repository.readSettings();

    expect(saved, isTrue);
    expect(settings.dailyKcalGoal, 2400);
    expect(settings.hasGoal, isTrue);
  });

  test('clearDailyGoal resets goal to empty settings', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieSettingsRepository(
      session: _FakeCalorieSettingsUserSession(currentUserId: 'user-1'),
      firestore: firestore,
    );

    await repository.setDailyGoal(2200);
    final cleared = await repository.clearDailyGoal();
    final settings = await repository.readSettings();

    expect(cleared, isTrue);
    expect(settings.dailyKcalGoal, isNull);
    expect(settings.hasGoal, isFalse);
  });

  test('watchSettings emits realtime updates', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieSettingsRepository(
      session: _FakeCalorieSettingsUserSession(currentUserId: 'user-1'),
      firestore: firestore,
    );

    final emitted = <CalorieGoalSettings>[];
    final subscription = repository.watchSettings().listen(emitted.add);
    addTearDown(() {
      unawaited(subscription.cancel());
    });

    await repository.setDailyGoal(2100);
    await Future<void>.delayed(const Duration(milliseconds: 1));

    expect(emitted, isNotEmpty);
    expect(emitted.last.dailyKcalGoal, 2100);
  });

  test('saveSettings persists calculator profile fields', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreCalorieSettingsRepository(
      session: _FakeCalorieSettingsUserSession(currentUserId: 'user-1'),
      firestore: firestore,
    );

    final settings = CalorieGoalSettings.single(
      dailyKcalGoal: 1850,
      calculatorProfile: const CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 28,
        activityLevel: 1.5,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
      ),
      effectiveDate: DateTime(2026, 2, 25, 11),
    );

    final saved = await repository.saveSettings(settings);
    final readBack = await repository.readSettings();

    expect(saved, isTrue);
    expect(readBack.dailyKcalGoal, 1850);
    expect(readBack.calculatorProfile?.sex, CalorieCalculatorSex.female);
    expect(readBack.calculatorProfile?.goalMode, CalorieGoalMode.lose);
    expect(readBack.calculatorProfile?.goalSpeedKgPerWeek, 0.5);
    expect(readBack.goalHistory, hasLength(1));
    expect(readBack.goalHistory.single.effectiveDate, DateTime(2026, 2, 25));
    expect(readBack.goalHistory.single.changedAt, DateTime(2026, 2, 25, 11));
  });

  test('readSettings hard migrates legacy calorie math document', () async {
    final now = DateTime(2026, 4, 24, 10, 30);
    const profile = CalorieCalculatorProfile(
      sex: CalorieCalculatorSex.female,
      weightKg: 65,
      heightCm: 170,
      ageYears: 28,
      activityLevel: 1.5,
      goalMode: CalorieGoalMode.lose,
      goalSpeedKgPerWeek: 0.5,
    );
    final firestore = FakeFirebaseFirestore();
    await firestore
        .collection('users')
        .doc('user-1')
        .collection('calorie_settings')
        .doc('default')
        .set({
          'daily_kcal_goal': 1850,
          'calculator_profile': profile.toJson(),
          'updated_at': DateTime(2026, 4, 18, 8),
          'goal_history': [
            {
              'daily_kcal_goal': 1850,
              'calculator_profile': profile.toJson(),
              'effective_date': DateTime(2026, 4, 18),
              'changed_at': DateTime(2026, 4, 18, 8),
              'counting_start_date': DateTime(2026, 4, 18),
              'source': 'calculator',
            },
          ],
          'pending_weekly_check_in': {
            'window_start_date': DateTime(2026, 4, 18),
            'window_end_date': DateTime(2026, 4, 24),
            'due_date': DateTime(2026, 4, 25),
          },
          'skipped_intake_day_keys': ['2026-4-18'],
          'eating_window_start_minute_of_day': 360,
          'eating_window_end_minute_of_day': 1320,
        });
    final repository = FirestoreCalorieSettingsRepository(
      session: _FakeCalorieSettingsUserSession(currentUserId: 'user-1'),
      firestore: firestore,
      now: () => now,
    );

    final settings = await repository.readSettings();

    expect(settings.calorieMathVersion, currentCalorieMathVersion);
    expect(settings.dailyKcalGoal, 1850);
    expect(settings.goalHistory, hasLength(1));
    expect(settings.goalHistory.single.effectiveDate, DateTime(2026, 4, 18));
    expect(settings.goalHistory.single.changedAt, DateTime(2026, 4, 18));
    expect(
      settings.goalHistory.single.effectiveCountingStartDate,
      DateTime(2026, 4, 18),
    );
    expect(
      settings.expectedActivityKcal,
      closeTo(
        CalorieGoalCalculator.calculate(profile).expectedActivityKcal,
        0.000001,
      ),
    );
    expect(settings.pendingWeeklyCheckIn, isNull);
    expect(settings.skippedIntakeDayKeys, isEmpty);

    final persistedSnapshot = await firestore
        .collection('users')
        .doc('user-1')
        .collection('calorie_settings')
        .doc('default')
        .get();
    final persisted = persistedSnapshot.data()!;
    expect(persisted['calorie_math_version'], currentCalorieMathVersion);
    expect(persisted.containsKey('eating_window_start_minute_of_day'), isFalse);
  });

  test(
    'readSettings preserves legacy top-level goal without history',
    () async {
      final now = DateTime(2026, 4, 24, 10, 30);
      const profile = CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.male,
        weightKg: 82,
        heightCm: 181,
        ageYears: 35,
        activityLevel: 1.4,
        goalMode: CalorieGoalMode.maintain,
        goalSpeedKgPerWeek: 0,
      );
      final firestore = FakeFirebaseFirestore();
      await firestore
          .collection('users')
          .doc('user-1')
          .collection('calorie_settings')
          .doc('default')
          .set({
            'daily_kcal_goal': 2300,
            'calculator_profile': profile.toJson(),
            'expected_activity_kcal': 420,
            'updated_at': DateTime(2026, 4, 2, 8),
          });
      final repository = FirestoreCalorieSettingsRepository(
        session: _FakeCalorieSettingsUserSession(currentUserId: 'user-1'),
        firestore: firestore,
        now: () => now,
      );

      final settings = await repository.readSettings();

      expect(settings.calorieMathVersion, currentCalorieMathVersion);
      expect(settings.dailyKcalGoal, 2300);
      expect(settings.hasGoal, isTrue);
      expect(settings.goalHistory, hasLength(1));
      expect(settings.goalHistory.single.dailyKcalGoal, 2300);
      expect(settings.expectedActivityKcal, 420);

      final persistedSnapshot = await firestore
          .collection('users')
          .doc('user-1')
          .collection('calorie_settings')
          .doc('default')
          .get();
      final persisted = persistedSnapshot.data()!;
      expect(persisted['daily_kcal_goal'], 2300);
      expect(persisted['calorie_math_version'], currentCalorieMathVersion);
      expect(persisted['goal_history'], hasLength(1));
    },
  );

  test('repository returns empty defaults when no user is signed in', () async {
    final repository = FirestoreCalorieSettingsRepository(
      session: _FakeCalorieSettingsUserSession(),
      firestore: FakeFirebaseFirestore(),
    );

    final watched = await repository.watchSettings().first;
    final read = await repository.readSettings();
    final setGoal = await repository.setDailyGoal(2000);

    expect(watched.dailyKcalGoal, isNull);
    expect(read.dailyKcalGoal, isNull);
    expect(setGoal, isFalse);
  });
}
