import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/data/payload_cipher.dart';
import 'package:yamt/features/auth/data/user_data_key_session.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

const _settingsPath = 'users/user-1/calorie_settings/default';

void main() {
  late UserDataCipher signedIn;

  setUpAll(() async {
    signedIn = (
      uid: 'user-1',
      cipher: PayloadCipher(await PayloadCipher.newDataKey()),
    );
  });

  FirestoreCalorieSettingsRepository repositoryFor(
    FakeFirebaseFirestore firestore,
  ) {
    return FirestoreCalorieSettingsRepository(
      dataCipher: signedIn,
      firestore: firestore,
    );
  }

  Future<void> seedSettings(
    FakeFirebaseFirestore firestore,
    Map<String, dynamic> json,
  ) async {
    await firestore.doc(_settingsPath).set(<String, dynamic>{
      'payload': await signedIn.cipher.encryptJson(json, aad: _settingsPath),
    });
  }

  test('setDailyGoal persists and readSettings returns value', () async {
    final repository = repositoryFor(FakeFirebaseFirestore());

    final saved = await repository.setDailyGoal(2400);
    final settings = await repository.readSettings();

    expect(saved, isTrue);
    expect(settings.dailyKcalGoal, 2400);
    expect(settings.hasGoal, isTrue);
  });

  test('stores only an encrypted payload', () async {
    final firestore = FakeFirebaseFirestore();

    await repositoryFor(firestore).setDailyGoal(2400);

    final stored = (await firestore.doc(_settingsPath).get()).data()!;
    expect(stored.keys, <String>['payload']);
    expect(stored['payload'], isNot(contains('2400')));
  });

  test('clearDailyGoal resets goal to empty settings', () async {
    final repository = repositoryFor(FakeFirebaseFirestore());

    await repository.setDailyGoal(2200);
    final cleared = await repository.clearDailyGoal();
    final settings = await repository.readSettings();

    expect(cleared, isTrue);
    expect(settings.dailyKcalGoal, isNull);
    expect(settings.hasGoal, isFalse);
  });

  test('watchSettings emits realtime updates', () async {
    final repository = repositoryFor(FakeFirebaseFirestore());

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
    final repository = repositoryFor(FakeFirebaseFirestore());

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

  test('readSettings decodes a full calorie settings payload', () async {
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
    await seedSettings(firestore, {
      'daily_kcal_goal': 1850,
      'calculator_profile': profile.toJson(),
      'calorie_math_version': currentCalorieMathVersion,
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
    });

    final settings = await repositoryFor(firestore).readSettings();

    expect(settings.calorieMathVersion, currentCalorieMathVersion);
    expect(settings.dailyKcalGoal, 1850);
    expect(settings.goalHistory, hasLength(1));
    expect(settings.goalHistory.single.effectiveDate, DateTime(2026, 4, 18));
    expect(settings.goalHistory.single.changedAt, DateTime(2026, 4, 18, 8));
    expect(
      settings.goalHistory.single.effectiveCountingStartDate,
      DateTime(2026, 4, 18),
    );
    expect(settings.pendingWeeklyCheckIn, isNotNull);
    expect(settings.skippedIntakeDayKeys, ['2026-4-18']);
  });

  test(
    'readSettings preserves top-level goal without synthesizing history',
    () async {
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
      await seedSettings(firestore, {
        'daily_kcal_goal': 2300,
        'calculator_profile': profile.toJson(),
        'calorie_math_version': currentCalorieMathVersion,
        'updated_at': DateTime(2026, 4, 2, 8),
      });

      final settings = await repositoryFor(firestore).readSettings();

      expect(settings.calorieMathVersion, currentCalorieMathVersion);
      expect(settings.dailyKcalGoal, 2300);
      expect(settings.hasGoal, isTrue);
      expect(settings.goalHistory, isEmpty);
    },
  );

  test('repository returns empty defaults when no user is signed in', () async {
    final repository = FirestoreCalorieSettingsRepository(
      dataCipher: null,
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
