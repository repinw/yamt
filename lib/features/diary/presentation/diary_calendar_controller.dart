import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/utils/date_utils.dart';

part 'diary_calendar_controller.g.dart';

/// Provides the current clock for diary calendar state.
@Riverpod(keepAlive: true)
DateTime Function() diaryCalendarNow(Ref ref) {
  return DateTime.now;
}

/// UI state for the diary calendar.
class DiaryCalendarState {
  /// Creates diary calendar state.
  const DiaryCalendarState({
    required this.today,
    required this.selectedDay,
    required this.todayRequest,
  });

  /// Today's normalized date.
  final DateTime today;

  /// The currently selected date.
  final DateTime selectedDay;

  /// Incremented when the app bar asks the calendar to scroll to today.
  final int todayRequest;

  /// Whether the selected date is today.
  bool get isSelectedToday => isSameCalendarDay(selectedDay, today);

  /// Returns a copy with selected overrides.
  DiaryCalendarState copyWith({
    DateTime? today,
    DateTime? selectedDay,
    int? todayRequest,
  }) {
    return DiaryCalendarState(
      today: today ?? this.today,
      selectedDay: selectedDay ?? this.selectedDay,
      todayRequest: todayRequest ?? this.todayRequest,
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
      todayRequest: 0,
    );
  }

  /// Selects [day].
  void selectDay(DateTime day) {
    final selectedDay = dateOnly(day);
    if (isSameCalendarDay(selectedDay, state.selectedDay)) {
      return;
    }

    state = state.copyWith(selectedDay: selectedDay);
  }

  /// Selects today and asks the calendar strip to scroll back to it.
  void selectToday() {
    final today = _currentToday();
    state = state.copyWith(
      today: today,
      selectedDay: today,
      todayRequest: state.todayRequest + 1,
    );
  }

  /// Refreshes the cached today value after app resume or midnight rollover.
  void refreshToday() {
    final today = _currentToday();
    if (isSameCalendarDay(today, state.today)) {
      return;
    }

    final wasSelectedToday = state.isSelectedToday;
    state = state.copyWith(
      today: today,
      selectedDay: wasSelectedToday ? today : state.selectedDay,
      todayRequest: wasSelectedToday
          ? state.todayRequest + 1
          : state.todayRequest,
    );
  }

  DateTime _currentToday() {
    return dateOnly(ref.read(diaryCalendarNowProvider)());
  }
}
