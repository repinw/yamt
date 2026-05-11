import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_dialog_scheduler.dart';

void main() {
  test('schedules and opens eligible dialog on next frame', () {
    final postFrameCallbacks = <VoidCallback>[];
    final scheduler = DiaryWeeklyCheckInDialogScheduler(
      schedulePostFrame: postFrameCallbacks.add,
    );
    addTearDown(scheduler.dispose);
    final opened = <CalorieWeeklyCheckInViewModel>[];
    final viewModel = _viewModel(DateTime(2026, 4, 20));

    scheduler.schedule(
      viewModel: viewModel,
      isMounted: () => true,
      openDialog: (viewModel) {
        opened.add(viewModel);
        return Future<void>.value();
      },
    );

    expect(opened, isEmpty);
    expect(postFrameCallbacks, hasLength(1));

    postFrameCallbacks.removeAt(0)();

    expect(opened, [viewModel]);
  });

  test('defers second dialog while one is open', () {
    final postFrameCallbacks = <VoidCallback>[];
    final scheduler = DiaryWeeklyCheckInDialogScheduler(
      schedulePostFrame: postFrameCallbacks.add,
    );
    addTearDown(scheduler.dispose);
    final opened = <CalorieWeeklyCheckInViewModel>[];
    final firstViewModel = _viewModel(DateTime(2026, 4, 13));
    final secondViewModel = _viewModel(DateTime(2026, 4, 20));

    expect(
      scheduler.beginDialog(
        viewModel: firstViewModel,
        isMounted: () => true,
      ),
      isTrue,
    );

    scheduler.schedule(
      viewModel: secondViewModel,
      isMounted: () => true,
      openDialog: (viewModel) {
        opened.add(viewModel);
        return Future<void>.value();
      },
    );

    expect(opened, isEmpty);
    expect(postFrameCallbacks, isEmpty);

    scheduler.endDialog(
      isMounted: () => true,
      openDialog: (viewModel) {
        opened.add(viewModel);
        return Future<void>.value();
      },
    );
    expect(postFrameCallbacks, hasLength(1));

    postFrameCallbacks.removeAt(0)();

    expect(opened, [secondViewModel]);
  });

  test('dispose cancels pending dialog opens', () {
    final postFrameCallbacks = <VoidCallback>[];
    final scheduler = DiaryWeeklyCheckInDialogScheduler(
      schedulePostFrame: postFrameCallbacks.add,
    );
    final opened = <CalorieWeeklyCheckInViewModel>[];

    scheduler.schedule(
      viewModel: _viewModel(DateTime(2026, 4, 20)),
      isMounted: () => true,
      openDialog: (viewModel) {
        opened.add(viewModel);
        return Future<void>.value();
      },
    );
    expect(postFrameCallbacks, hasLength(1));

    scheduler.dispose();

    postFrameCallbacks.removeAt(0)();

    expect(opened, isEmpty);
  });
}

CalorieWeeklyCheckInViewModel _viewModel(DateTime windowStartDate) {
  return CalorieWeeklyCheckInViewModel(
    pendingWeeklyCheckIn: PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: windowStartDate,
      windowEndDate: windowStartDate.add(const Duration(days: 6)),
      dueDate: windowStartDate.add(const Duration(days: 7)),
    ),
    shouldAutoOpen: true,
    days: const <CalorieWeeklyCheckInWindowDay>[],
    calculation: null,
    blockedReason: null,
    missingIntakeDays: const <DateTime>[],
    missingWeightDays: const <DateTime>[],
    freshness: CalorieLearnedTdeeFreshness.none,
    latestLearnedTdeeAt: null,
    lowConfidence: false,
  );
}
