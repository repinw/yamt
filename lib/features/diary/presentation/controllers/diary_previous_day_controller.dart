import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_day_log_service.dart';

part 'diary_previous_day_controller.g.dart';

/// Closes or reopens the day before a planned day, so the planned day counts
/// like a started day with its carryover.
@riverpod
class DiaryPreviousDayController extends _$DiaryPreviousDayController {
  @override
  FutureOr<void> build() {}

  /// Closes [day]. Returns false when the device did not save it.
  Future<bool> close(DateTime day) => _save((dayLog) => dayLog.closeDay(day));

  /// Opens the closed day again. Returns false when the device did not save
  /// it.
  Future<bool> reopen() => _save((dayLog) => dayLog.reopenDay());

  Future<bool> _save(
    Future<void> Function(CalorieDayLogService dayLog) write,
  ) async {
    final dayLog = ref.read(calorieDayLogServiceProvider);
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => write(dayLog));
    if (ref.mounted) {
      state = result;
    }
    return !result.hasError;
  }
}
