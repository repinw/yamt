import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/data/burn_week_run_state_repository.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

import '../../../helpers/memory_app_preferences.dart';

void main() {
  test('readState returns initial state when nothing stored', () async {
    final repository = AppPreferencesBurnWeekRunStateRepository(
      preferences: MemoryAppPreferences(),
    );

    final state = await repository.readState();

    expect(state.runWeekNumber, 1);
    expect(state.starCount, 0);
    expect(state.heartCount, 3);
    expect(state.lastActiveDayKey, isNull);
  });

  test('saveState persists json and readState restores it', () async {
    final preferences = MemoryAppPreferences();
    final repository = AppPreferencesBurnWeekRunStateRepository(
      preferences: preferences,
    );
    const savedState = BurnWeekRunState(
      currentWeekStartDayKey: '2026-04-21',
      runWeekNumber: 3,
      starCount: 2,
      heartCount: 2,
      heartCreditKcal: 700,
      starBrokeThisWeek: true,
      missedTrackingThisWeek: false,
    );

    final saved = await repository.saveState(savedState);
    final restored = await repository.readState();

    expect(saved, isTrue);
    expect(restored.currentWeekStartDayKey, '2026-04-21');
    expect(restored.lastActiveDayKey, isNull);
    expect(restored.runWeekNumber, 3);
    expect(restored.starCount, 2);
    expect(restored.heartCount, 2);
    expect(restored.heartCreditKcal, 700);
    expect(restored.starBrokeThisWeek, isTrue);
  });

  test('readState falls back to initial on invalid json', () async {
    final preferences = MemoryAppPreferences(
      initialStrings: <String, String>{
        burnWeekRunStatePreferenceKey: '{bad json',
      },
    );
    final repository = AppPreferencesBurnWeekRunStateRepository(
      preferences: preferences,
    );

    final state = await repository.readState();

    expect(state.runWeekNumber, 1);
    expect(state.starCount, 0);
    expect(state.heartCount, 3);
  });

  test(
    'different storage keys keep different live-user states apart',
    () async {
      final preferences = MemoryAppPreferences();
      final leftRepository = AppPreferencesBurnWeekRunStateRepository(
        preferences: preferences,
        storageKey: 'burn_week_run_state_v2::user-a',
      );
      final rightRepository = AppPreferencesBurnWeekRunStateRepository(
        preferences: preferences,
        storageKey: 'burn_week_run_state_v2::user-b',
      );

      await leftRepository.saveState(
        const BurnWeekRunState(
          currentWeekStartDayKey: '2026-04-21',
          runWeekNumber: 4,
          starCount: 2,
          heartCount: 1,
          heartCreditKcal: 500,
          starBrokeThisWeek: true,
          missedTrackingThisWeek: false,
        ),
      );

      final leftState = await leftRepository.readState();
      final rightState = await rightRepository.readState();

      expect(leftState.runWeekNumber, 4);
      expect(leftState.starCount, 2);
      expect(leftState.heartCount, 1);
      expect(rightState.runWeekNumber, 1);
      expect(rightState.starCount, 0);
      expect(rightState.heartCount, 3);
    },
  );

  test('storage key waits for auth instead of falling back to guest', () {
    expect(
      resolveBurnWeekRunStateStorageKey(
        authStateIsLoading: true,
        currentUserId: null,
      ),
      isNull,
    );
    expect(
      resolveBurnWeekRunStateStorageKey(
        authStateIsLoading: false,
        currentUserId: null,
      ),
      'burn_week_run_state_v2::guest',
    );
    expect(
      resolveBurnWeekRunStateStorageKey(
        authStateIsLoading: true,
        currentUserId: 'user-1',
      ),
      'burn_week_run_state_v2::user-1',
    );
  });
}
