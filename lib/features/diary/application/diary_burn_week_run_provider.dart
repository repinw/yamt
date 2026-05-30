import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';
import 'package:yamt/features/calories/provider/burn_week_run_controller.dart';

part 'diary_burn_week_run_provider.g.dart';

/// Diary-facing Burn Week run state adapter.
@riverpod
AsyncValue<BurnWeekRunState> diaryBurnWeekRunState(Ref ref) {
  return ref.watch(burnWeekRunControllerProvider);
}

/// Actions needed by diary Burn Week presentation widgets.
@riverpod
DiaryBurnWeekRunActions diaryBurnWeekRunActions(Ref ref) {
  final controller = ref.read(burnWeekRunControllerProvider.notifier);
  return DiaryBurnWeekRunActions(
    useHeartForDay: controller.useHeartForDay,
  );
}

/// Operations that bridge diary Burn Week UI to application state.
class DiaryBurnWeekRunActions {
  /// Creates diary Burn Week actions.
  const DiaryBurnWeekRunActions({
    required Future<void> Function(DateTime day) useHeartForDay,
  }) : _useHeartForDay = useHeartForDay;

  final Future<void> Function(DateTime day) _useHeartForDay;

  /// Marks [day] as a heart day in the active Burn Week run.
  Future<void> useHeartForDay(DateTime day) {
    return _useHeartForDay(day);
  }
}
