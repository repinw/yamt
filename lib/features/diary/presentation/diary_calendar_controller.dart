import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/calories/application/last_planned_day_provider.dart';
import 'package:yamt/features/calories/domain/diary_day_status.dart';
import 'package:yamt/features/diary/application/diary_plan_start_day_provider.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';

part 'diary_calendar_controller.g.dart';

/// Selectable range for the current diary calendar state.
@riverpod
DiaryCalendarBounds diaryCalendarBounds(Ref ref) {
  return DiaryCalendarBounds.resolve(
    today: ref.watch(
      diaryCalendarControllerProvider.select((state) => state.today),
    ),
    planStartDay: ref.watch(diaryPlanStartDayProvider),
  );
}

/// UI state for the diary calendar.
class DiaryCalendarState {
  /// Creates diary calendar state.
  const new({required this.today, required this.selectedDay});

  /// Today's normalized date.
  final DateTime today;

  /// The currently selected date.
  final DateTime selectedDay;

  /// Whether the selected date is today.
  bool get isSelectedToday => isSameCalendarDay(selectedDay, today);

  /// Whether [day] lies after today, so the diary shows it as a plan.
  bool isFutureDay(DateTime day) =>
      DiaryDayStatus.of(day: day, today: today).isFuture;

  /// Returns a copy with selected overrides.
  DiaryCalendarState copyWith({DateTime? today, DateTime? selectedDay}) {
    return DiaryCalendarState(
      today: today ?? this.today,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }
}

/// Stores the diary calendar selection shared by the shell app bar and page.
@riverpod
class DiaryCalendarController extends _$DiaryCalendarController {
  @override
  DiaryCalendarState build() {
    // A new plan opens its day.
    ref.listen(lastPlannedDayProvider, (_, planned) {
      if (planned != null) {
        selectDay(planned.day);
      }
    });
    final today = ref.watch(diaryTodayProvider);
    // When today moves on, a selected today moves along and another selected
    // day stays.
    final previous = stateOrNull;
    return DiaryCalendarState(
      today: today,
      selectedDay: previous == null || previous.isSelectedToday
          ? today
          : previous.selectedDay,
    );
  }

  /// Selects [day], clamped to the selectable range.
  void selectDay(DateTime day) {
    final selectedDay = _bounds().clamp(day);
    if (isSameCalendarDay(selectedDay, state.selectedDay)) {
      return;
    }

    state = state.copyWith(selectedDay: selectedDay);
  }

  /// Selects the day before the current selection.
  void selectPreviousDay() {
    selectDay(previousLocalDay(state.selectedDay));
  }

  /// Selects the day after the current selection.
  void selectNextDay() {
    selectDay(nextLocalDay(state.selectedDay));
  }

  DiaryCalendarBounds _bounds() {
    return DiaryCalendarBounds.resolve(
      today: state.today,
      planStartDay: ref.read(diaryPlanStartDayProvider),
    );
  }
}
