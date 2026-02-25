import 'dart:async';
import 'dart:developer' show log;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/data/calorie_settings_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

part 'calorie_goal_controller.g.dart';

const _goalControllerLogName = 'CalorieGoalController';

@riverpod
class CalorieGoalController extends _$CalorieGoalController {
  StreamSubscription<CalorieGoalSettings>? _settingsSubscription;

  @override
  FutureOr<CalorieGoalSettings> build() {
    ref.watch(calorieSettingsRepositoryProvider);
    ref.onDispose(_disposeSubscription);
    return _restartSubscription();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(_restartSubscription);
    if (!ref.mounted) {
      return;
    }
    state = next;
  }

  Future<bool> setGoal(double dailyKcalGoal) async {
    if (dailyKcalGoal <= 0) {
      return false;
    }

    final previous = state.asData?.value;
    final nextSettings = CalorieGoalSettings(
      dailyKcalGoal: dailyKcalGoal,
      updatedAt: DateTime.now(),
    );
    if (ref.mounted) {
      state = AsyncData(nextSettings);
    }

    final repository = ref.read(calorieSettingsRepositoryProvider);
    try {
      final saved = await repository.setDailyGoal(dailyKcalGoal);
      if (!saved && ref.mounted && previous != null) {
        state = AsyncData(previous);
      }
      return saved;
    } catch (error, stackTrace) {
      log(
        'Failed to persist calorie goal.',
        name: _goalControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted && previous != null) {
        state = AsyncData(previous);
      }
      return false;
    }
  }

  Future<bool> clearGoal() async {
    final previous = state.asData?.value;
    if (ref.mounted) {
      state = const AsyncData(CalorieGoalSettings.empty());
    }

    final repository = ref.read(calorieSettingsRepositoryProvider);
    try {
      final saved = await repository.clearDailyGoal();
      if (!saved && ref.mounted && previous != null) {
        state = AsyncData(previous);
      }
      return saved;
    } catch (error, stackTrace) {
      log(
        'Failed to clear calorie goal.',
        name: _goalControllerLogName,
        error: error,
        stackTrace: stackTrace,
      );
      if (ref.mounted && previous != null) {
        state = AsyncData(previous);
      }
      return false;
    }
  }

  Future<CalorieGoalSettings> _restartSubscription() {
    final initial = Completer<CalorieGoalSettings>();
    final repository = ref.read(calorieSettingsRepositoryProvider);
    _disposeSubscription();

    _settingsSubscription = repository.watchSettings().listen(
      (settings) {
        if (!initial.isCompleted) {
          initial.complete(settings);
          return;
        }
        _onRealtimeSettings(settings);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!initial.isCompleted) {
          initial.completeError(error, stackTrace);
          return;
        }
        _onRealtimeError(error, stackTrace);
      },
    );

    return initial.future;
  }

  void _disposeSubscription() {
    final currentSubscription = _settingsSubscription;
    _settingsSubscription = null;
    if (currentSubscription != null) {
      unawaited(currentSubscription.cancel());
    }
  }

  void _onRealtimeSettings(CalorieGoalSettings settings) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncData(settings);
  }

  void _onRealtimeError(Object error, StackTrace stackTrace) {
    if (!ref.mounted) {
      return;
    }
    state = AsyncError(error, stackTrace);
  }
}
