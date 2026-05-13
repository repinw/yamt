import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/auth/provider/auth_service.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/onboarding/domain/'
    'calorie_goal_onboarding_preferences.dart';
import 'package:yamt/features/onboarding/provider/'
    'calorie_goal_onboarding_completed_provider.dart';

import '../../../helpers/memory_app_preferences.dart';

class _MockUser extends Mock implements User {}

final _markCompletionProvider = FutureProvider<void>(
  markCalorieGoalOnboardingCompleted,
);

final _markExplicitCompletionProvider = FutureProvider<void>((ref) {
  return markCalorieGoalOnboardingCompleted(ref, userId: 'explicit-user');
});

void main() {
  group('calorieGoalOnboardingCompletedProvider', () {
    test('returns false when no user is signed in', () async {
      final preferences = MemoryAppPreferences();
      final container = _container(
        preferences: preferences,
        user: null,
        settingsRepository: const _StaticCalorieSettingsRepository(
          CalorieGoalSettings.empty(),
        ),
      );
      addTearDown(container.dispose);
      await _seedAuthState(container);

      await expectLater(
        container.read(calorieGoalOnboardingCompletedProvider.future),
        completion(isFalse),
      );
    });

    test('returns true from the local completion marker', () async {
      final preferences = MemoryAppPreferences(
        completedCalorieGoalOnboardingUserIds: {'user-1'},
      );
      final container = _container(
        preferences: preferences,
        user: _user('user-1'),
        settingsRepository: const _ThrowingCalorieSettingsRepository(),
      );
      addTearDown(container.dispose);
      await _seedAuthState(container);

      await expectLater(
        container.read(calorieGoalOnboardingCompletedProvider.future),
        completion(isTrue),
      );
    });

    test(
      'marks onboarding complete when settings already contain a goal',
      () async {
        final preferences = MemoryAppPreferences();
        final settings = CalorieGoalSettings.single(
          dailyKcalGoal: 2100,
          calculatorProfile: null,
          effectiveDate: DateTime(2026, 5, 13, 8),
        );
        final container = _container(
          preferences: preferences,
          user: _user('user-2'),
          settingsRepository: _StaticCalorieSettingsRepository(settings),
        );
        addTearDown(container.dispose);
        await _seedAuthState(container);

        await expectLater(
          container.read(calorieGoalOnboardingCompletedProvider.future),
          completion(isTrue),
        );
        expect(
          preferences.getStringSync(calorieGoalOnboardingKeyForUser('user-2')),
          calorieGoalOnboardingCompletedValue,
        );
      },
    );

    test('returns false without marker or saved goal', () async {
      final preferences = MemoryAppPreferences();
      final container = _container(
        preferences: preferences,
        user: _user('user-3'),
        settingsRepository: const _StaticCalorieSettingsRepository(
          CalorieGoalSettings.empty(),
        ),
      );
      addTearDown(container.dispose);
      await _seedAuthState(container);

      await expectLater(
        container.read(calorieGoalOnboardingCompletedProvider.future),
        completion(isFalse),
      );
      expect(
        preferences.getStringSync(calorieGoalOnboardingKeyForUser('user-3')),
        isNull,
      );
    });

    test('mark helper writes the current user marker', () async {
      final preferences = MemoryAppPreferences();
      final container = _container(
        preferences: preferences,
        user: _user('user-4'),
        settingsRepository: const _StaticCalorieSettingsRepository(
          CalorieGoalSettings.empty(),
        ),
      );
      addTearDown(container.dispose);
      await _seedAuthState(container);

      await container.read(_markCompletionProvider.future);

      expect(
        preferences.getStringSync(calorieGoalOnboardingKeyForUser('user-4')),
        calorieGoalOnboardingCompletedValue,
      );
    });

    test('mark helper writes an explicit user marker without auth', () async {
      final preferences = MemoryAppPreferences();
      final container = _container(
        preferences: preferences,
        user: null,
        settingsRepository: const _StaticCalorieSettingsRepository(
          CalorieGoalSettings.empty(),
        ),
      );
      addTearDown(container.dispose);
      await _seedAuthState(container);

      await container.read(_markExplicitCompletionProvider.future);

      expect(
        preferences.getStringSync(
          calorieGoalOnboardingKeyForUser('explicit-user'),
        ),
        calorieGoalOnboardingCompletedValue,
      );
    });

    test('mark helper is a no-op without current or explicit user', () async {
      final preferences = MemoryAppPreferences();
      final container = _container(
        preferences: preferences,
        user: null,
        settingsRepository: const _StaticCalorieSettingsRepository(
          CalorieGoalSettings.empty(),
        ),
      );
      addTearDown(container.dispose);
      await _seedAuthState(container);

      await container.read(_markCompletionProvider.future);

      expect(
        preferences.getStringSync(calorieGoalOnboardingKeyForUser('')),
        isNull,
      );
      await expectLater(
        container.read(calorieGoalOnboardingCompletedProvider.future),
        completion(isFalse),
      );
    });

    test(
      'container helper writes marker and refreshes completion state',
      () async {
        final preferences = MemoryAppPreferences();
        final container = _container(
          preferences: preferences,
          user: _user('container-user'),
          settingsRepository: const _StaticCalorieSettingsRepository(
            CalorieGoalSettings.empty(),
          ),
        );
        addTearDown(container.dispose);
        await _seedAuthState(container);

        await expectLater(
          container.read(calorieGoalOnboardingCompletedProvider.future),
          completion(isFalse),
        );
        await markCalorieGoalOnboardingCompletedFromContainer(container);

        await expectLater(
          container.read(calorieGoalOnboardingCompletedProvider.future),
          completion(isTrue),
        );
        expect(
          preferences.getStringSync(
            calorieGoalOnboardingKeyForUser('container-user'),
          ),
          calorieGoalOnboardingCompletedValue,
        );
      },
    );
  });
}

ProviderContainer _container({
  required AppPreferences preferences,
  required User? user,
  required CalorieSettingsRepository settingsRepository,
}) {
  return ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(preferences),
      authStateChangesProvider.overrideWith((ref) => _authStateStream(user)),
      calorieSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    ],
  );
}

Future<void> _seedAuthState(ProviderContainer container) async {
  final subscription = container.listen(
    authStateChangesProvider,
    (previous, next) {},
  );
  await Future<void>.delayed(Duration.zero);
  subscription.close();
}

Stream<User?> _authStateStream(User? user) {
  late final StreamController<User?> controller;
  controller = StreamController<User?>(
    sync: true,
    onListen: () {
      controller.add(user);
      unawaited(controller.close());
    },
  );
  return controller.stream;
}

User _user(String uid) {
  final user = _MockUser();
  when(() => user.uid).thenReturn(uid);
  return user;
}

class _StaticCalorieSettingsRepository implements CalorieSettingsRepository {
  const _StaticCalorieSettingsRepository(this.settings);

  final CalorieGoalSettings settings;

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    return Stream<CalorieGoalSettings>.value(settings);
  }

  @override
  Future<CalorieGoalSettings> readSettings() async => settings;

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async => true;

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) async => true;

  @override
  Future<bool> clearDailyGoal() async => true;
}

class _ThrowingCalorieSettingsRepository implements CalorieSettingsRepository {
  const _ThrowingCalorieSettingsRepository();

  @override
  Stream<CalorieGoalSettings> watchSettings() {
    throw StateError('settings should not be watched');
  }

  @override
  Future<CalorieGoalSettings> readSettings() {
    throw StateError('settings should not be read');
  }

  @override
  Future<bool> saveSettings(CalorieGoalSettings settings) async => true;

  @override
  Future<bool> setDailyGoal(double dailyKcalGoal) async => true;

  @override
  Future<bool> clearDailyGoal() async => true;
}
