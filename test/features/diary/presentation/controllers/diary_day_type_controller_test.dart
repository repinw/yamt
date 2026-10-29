import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_type_controller.dart';

class _RecordingCalorieGoalController extends CalorieGoalController {
  new(this.settings, {this.saves = true});

  final CalorieGoalSettings settings;
  final bool saves;
  final calls = <String>[];

  @override
  CalorieGoalSettings build() => settings;

  @override
  Future<bool> setPauseDay({
    required DateTime day,
    required bool isPause,
  }) async {
    calls.add('pause:$isPause');
    return saves;
  }

  @override
  Future<bool> toggleTrainingDay(DateTime day) async {
    calls.add('toggleTraining');
    return saves;
  }
}

final _monday = DateTime(2026, 4, 27);
final _tuesday = DateTime(2026, 4, 28);

Future<(ProviderContainer, _RecordingCalorieGoalController)> _setUp({
  List<String> pauseDayKeys = const [],
  bool saves = true,
}) async {
  final controller = _RecordingCalorieGoalController(
    const CalorieGoalSettings.empty().copyWith(
      dailyKcalGoal: 2200,
      trainingWeekdays: const [DateTime.monday],
      trainingDayKcalOffset: 150,
      pauseDayKeys: pauseDayKeys,
    ),
    saves: saves,
  );
  final container = ProviderContainer(
    overrides: [calorieGoalControllerProvider.overrideWith(() => controller)],
  );
  addTearDown(container.dispose);
  container.listen(calorieGoalControllerProvider, (_, _) {});
  await container.read(calorieGoalControllerProvider.future);
  return (container, controller);
}

void main() {
  test('marking a normal day as training toggles training once', () async {
    final (container, controller) = await _setUp();

    await container
        .read(diaryDayTypeControllerProvider.notifier)
        .select(_tuesday, DiaryDayType.training);

    expect(controller.calls, ['toggleTraining']);
  });

  test('marking a pause day as normal unpauses without toggling', () async {
    final (container, controller) = await _setUp(
      pauseDayKeys: [localDayKey(_tuesday)],
    );

    await container
        .read(diaryDayTypeControllerProvider.notifier)
        .select(_tuesday, DiaryDayType.normal);

    expect(controller.calls, ['pause:false']);
  });

  test('selecting pause on a training day pauses it', () async {
    final (container, controller) = await _setUp();

    await container
        .read(diaryDayTypeControllerProvider.notifier)
        .select(_monday, DiaryDayType.pause);

    expect(controller.calls, ['pause:true']);
  });

  test('selecting pause on a pause day keeps it paused', () async {
    final (container, controller) = await _setUp(
      pauseDayKeys: [localDayKey(_tuesday)],
    );

    await container
        .read(diaryDayTypeControllerProvider.notifier)
        .select(_tuesday, DiaryDayType.pause);

    expect(controller.calls, isEmpty);
  });

  test('a change that was not saved reports false and an error', () async {
    final (container, controller) = await _setUp(
      pauseDayKeys: [localDayKey(_tuesday)],
      saves: false,
    );

    final saved = await container
        .read(diaryDayTypeControllerProvider.notifier)
        .select(_tuesday, DiaryDayType.training);

    // The training mark waits until the pause is gone.
    expect(saved, isFalse);
    expect(controller.calls, ['pause:false']);
    expect(container.read(diaryDayTypeControllerProvider).hasError, isTrue);
  });
}
