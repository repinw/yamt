import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/diary/application/diary_day_type_provider.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart'
    show diaryCalorieGoalSettingsProvider;
import 'package:yamt/features/diary/domain/diary_day_type.dart';

class _RecordingCalorieGoalController extends CalorieGoalController {
  _RecordingCalorieGoalController(this.settings);

  final CalorieGoalSettings settings;
  final calls = <String>[];

  @override
  CalorieGoalSettings build() => settings;

  @override
  Future<bool> setPauseDay({
    required DateTime day,
    required bool isPause,
  }) async {
    calls.add('pause:$isPause');
    return true;
  }

  @override
  Future<bool> toggleTrainingDay(DateTime day) async {
    calls.add('toggleTraining');
    return true;
  }
}

final _monday = DateTime(2026, 4, 27);
final _tuesday = DateTime(2026, 4, 28);

Future<(ProviderContainer, _RecordingCalorieGoalController)> _setUp({
  List<String> pauseDayKeys = const [],
}) async {
  final controller = _RecordingCalorieGoalController(
    const CalorieGoalSettings.empty().copyWith(
      dailyKcalGoal: 2200,
      trainingWeekdays: const [DateTime.monday],
      trainingDayKcalOffset: 150,
      pauseDayKeys: pauseDayKeys,
    ),
  );
  final container = ProviderContainer(
    overrides: [calorieGoalControllerProvider.overrideWith(() => controller)],
  );
  addTearDown(container.dispose);
  container.listen(diaryCalorieGoalSettingsProvider, (_, _) {});
  await container.read(diaryCalorieGoalSettingsProvider.future);
  return (container, controller);
}

void main() {
  test('resolves the day type status from goal settings', () async {
    final (container, _) = await _setUp(
      pauseDayKeys: [diaryDayKey(_tuesday)],
    );

    final monday = container.read(diaryDayTypeStatusProvider(_monday));
    expect(monday?.type, DiaryDayType.training);
    expect(monday?.trainingDayKcalOffset, 150);
    expect(
      container.read(diaryDayTypeStatusProvider(_tuesday))?.type,
      DiaryDayType.pause,
    );
  });

  test('marking a rest day as training toggles training once', () async {
    final (container, controller) = await _setUp();

    await container
        .read(diaryDayTypeUpdaterProvider)
        .select(_tuesday, DiaryDayType.training);

    expect(controller.calls, ['toggleTraining']);
  });

  test('marking a pause day as rest unpauses without toggling', () async {
    final (container, controller) = await _setUp(
      pauseDayKeys: [diaryDayKey(_tuesday)],
    );

    await container
        .read(diaryDayTypeUpdaterProvider)
        .select(_tuesday, DiaryDayType.rest);

    expect(controller.calls, ['pause:false']);
  });

  test('selecting pause on a training day pauses it', () async {
    final (container, controller) = await _setUp();

    await container
        .read(diaryDayTypeUpdaterProvider)
        .select(_monday, DiaryDayType.pause);

    expect(controller.calls, ['pause:true']);
  });
}
