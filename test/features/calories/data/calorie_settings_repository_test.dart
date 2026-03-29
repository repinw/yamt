import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
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

    const settings = CalorieGoalSettings(
      dailyKcalGoal: 1850,
      calculatorProfile: CalorieCalculatorProfile(
        sex: CalorieCalculatorSex.female,
        weightKg: 65,
        heightCm: 170,
        ageYears: 28,
        activityLevel: 1.5,
        goalMode: CalorieGoalMode.lose,
        goalSpeedKgPerWeek: 0.5,
      ),
      updatedAt: null,
    );

    final saved = await repository.saveSettings(settings);
    final readBack = await repository.readSettings();

    expect(saved, isTrue);
    expect(readBack.dailyKcalGoal, 1850);
    expect(readBack.calculatorProfile?.sex, CalorieCalculatorSex.female);
    expect(readBack.calculatorProfile?.goalMode, CalorieGoalMode.lose);
    expect(readBack.calculatorProfile?.goalSpeedKgPerWeek, 0.5);
  });

  test('repository returns empty defaults when no user is signed in', () async {
    final repository = FirestoreCalorieSettingsRepository(
      session: _FakeCalorieSettingsUserSession(currentUserId: null),
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
