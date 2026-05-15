import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart'
    show DiaryWeeklyCheckInData;
import 'package:yamt/features/diary/presentation/'
    'diary_weekly_checkin_dialog_scheduler.dart';

void main() {
  test('schedules and opens eligible dialog on next frame', () {
    final postFrameCallbacks = <VoidCallback>[];
    final scheduler = DiaryWeeklyCheckInDialogScheduler(
      schedulePostFrame: postFrameCallbacks.add,
    );
    addTearDown(scheduler.dispose);
    final opened = <DiaryWeeklyCheckInData>[];
    final checkInData = _checkInData(DateTime(2026, 4, 20));

    scheduler.schedule(
      checkInData: checkInData,
      isMounted: () => true,
      openDialog: (checkInData) {
        opened.add(checkInData);
        return Future<void>.value();
      },
    );

    expect(opened, isEmpty);
    expect(postFrameCallbacks, hasLength(1));

    postFrameCallbacks.removeAt(0)();

    expect(opened, [checkInData]);
  });

  test('defers second dialog while one is open', () {
    final postFrameCallbacks = <VoidCallback>[];
    final scheduler = DiaryWeeklyCheckInDialogScheduler(
      schedulePostFrame: postFrameCallbacks.add,
    );
    addTearDown(scheduler.dispose);
    final opened = <DiaryWeeklyCheckInData>[];
    final firstCheckInData = _checkInData(DateTime(2026, 4, 13));
    final secondCheckInData = _checkInData(DateTime(2026, 4, 20));

    expect(
      scheduler.beginDialog(
        checkInData: firstCheckInData,
        isMounted: () => true,
      ),
      isTrue,
    );

    scheduler.schedule(
      checkInData: secondCheckInData,
      isMounted: () => true,
      openDialog: (checkInData) {
        opened.add(checkInData);
        return Future<void>.value();
      },
    );

    expect(opened, isEmpty);
    expect(postFrameCallbacks, isEmpty);

    scheduler.endDialog(
      isMounted: () => true,
      openDialog: (checkInData) {
        opened.add(checkInData);
        return Future<void>.value();
      },
    );
    expect(postFrameCallbacks, hasLength(1));

    postFrameCallbacks.removeAt(0)();

    expect(opened, [secondCheckInData]);
  });

  test('dispose cancels pending dialog opens', () {
    final postFrameCallbacks = <VoidCallback>[];
    final scheduler = DiaryWeeklyCheckInDialogScheduler(
      schedulePostFrame: postFrameCallbacks.add,
    );
    final opened = <DiaryWeeklyCheckInData>[];

    scheduler.schedule(
      checkInData: _checkInData(DateTime(2026, 4, 20)),
      isMounted: () => true,
      openDialog: (checkInData) {
        opened.add(checkInData);
        return Future<void>.value();
      },
    );
    expect(postFrameCallbacks, hasLength(1));

    scheduler.dispose();

    postFrameCallbacks.removeAt(0)();

    expect(opened, isEmpty);
  });
}

DiaryWeeklyCheckInData _checkInData(DateTime windowStartDate) {
  return DiaryWeeklyCheckInData(
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
