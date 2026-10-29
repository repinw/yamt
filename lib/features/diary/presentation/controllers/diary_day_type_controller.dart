import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';

part 'diary_day_type_controller.g.dart';

/// Changes the day type of a diary day through the calorie goal controller.
@riverpod
class DiaryDayTypeController extends _$DiaryDayTypeController {
  @override
  FutureOr<void> build() {}

  /// Marks [day] as [type]. Returns false when the change was not saved.
  Future<bool> select(DateTime day, DiaryDayType type) async {
    final goal = ref.read(calorieGoalControllerProvider.notifier);
    final settings = ref.read(calorieGoalControllerProvider).value;
    if (settings == null) {
      return false;
    }
    final isPause = settings.isPauseDay(day);
    final wantsPause = type == DiaryDayType.pause;
    final wantsTraining = type == DiaryDayType.training;

    // A change keeps running after the card that started it leaves the
    // screen, such as on a swipe to another day.
    final keepAlive = ref.keepAlive();
    state = const AsyncLoading();
    var saved = true;
    if (isPause != wantsPause) {
      saved = await goal.setPauseDay(day: day, isPause: wantsPause);
    }
    // A pause day keeps its training mark for when it is a normal day again.
    if (saved && !wantsPause && settings.isTrainingDay(day) != wantsTraining) {
      saved = await goal.toggleTrainingDay(day);
    }
    state = saved
        ? const AsyncData(null)
        : AsyncError(StateError('day type not saved'), StackTrace.current);
    keepAlive.close();
    return saved;
  }
}
