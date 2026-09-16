import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/diary/application/diary_plan_start_day_provider.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';

part 'diary_calendar_controller.g.dart';

/// Provides the current clock for diary calendar state.
@Riverpod(keepAlive: true)
DateTime Function() diaryCalendarNow(Ref ref) {
  return DateTime.now;
}

/// Selectable range for the current diary calendar state.
@riverpod
DiaryCalendarBounds diaryCalendarBounds(Ref ref) {
  return DiaryCalendarBounds.resolve(
    today: ref.watch(diaryCalendarControllerProvider).today,
    planStartDay: ref.watch(diaryPlanStartDayProvider),
  );
}

/// UI state for the diary calendar.
class DiaryCalendarState {
  /// Creates diary calendar state.
  const DiaryCalendarState({
    required this.today,
    required this.selectedDay,
  });

  /// Today's normalized date.
  final DateTime today;

  /// The currently selected date.
  final DateTime selectedDay;

  /// Whether the selected date is today.
  bool get isSelectedToday => isSameCalendarDay(selectedDay, today);

  /// Returns a copy with selected overrides.
  DiaryCalendarState copyWith({
    DateTime? today,
    DateTime? selectedDay,
  }) {
    return DiaryCalendarState(
      today: today ?? this.today,
      selectedDay: selectedDay ?? this.selectedDay,
    );
  }
}

/// Stores the diary calendar selection shared by the shell app bar and page.
@Riverpod(keepAlive: true)
class DiaryCalendarController extends _$DiaryCalendarController {
  @override
  DiaryCalendarState build() {
    final today = _currentToday();
    return DiaryCalendarState(
      today: today,
      selectedDay: today,
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

  /// Refreshes the cached today value after app resume or midnight rollover.
  void refreshToday() {
    final today = _currentToday();
    if (isSameCalendarDay(today, state.today)) {
      return;
    }

    state = state.copyWith(
      today: today,
      selectedDay: state.isSelectedToday ? today : state.selectedDay,
    );
  }

  DiaryCalendarBounds _bounds() {
    return DiaryCalendarBounds.resolve(
      today: state.today,
      planStartDay: ref.read(diaryPlanStartDayProvider),
    );
  }

  DateTime _currentToday() {
    return dateOnly(ref.read(diaryCalendarNowProvider)());
  }
}
