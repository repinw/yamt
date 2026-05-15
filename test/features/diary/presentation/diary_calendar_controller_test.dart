import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';

void main() {
  test('initial state starts on normalized today', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final state = container.read(diaryCalendarControllerProvider);

    expect(state.today, dateOnly(DateTime.now()));
    expect(state.selectedDay, state.today);
    expect(state.todayRequest, 0);
    expect(state.isSelectedToday, isTrue);
  });

  test(
    'selectDay normalizes the selected day and ignores same-day changes',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(diaryCalendarControllerProvider.notifier)
        ..selectDay(DateTime(2026, 4, 27, 16, 45))
        ..selectDay(DateTime(2026, 4, 27, 22, 30));
      final state = container.read(diaryCalendarControllerProvider);

      expect(state.selectedDay, DateTime(2026, 4, 27));
      expect(state.todayRequest, 0);
    },
  );

  test('selectToday updates today and increments the scroll request', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(diaryCalendarControllerProvider.notifier)
      ..selectDay(DateTime(2026, 4, 27))
      ..selectToday();
    final state = container.read(diaryCalendarControllerProvider);

    expect(state.today, dateOnly(DateTime.now()));
    expect(state.selectedDay, state.today);
    expect(state.todayRequest, 1);
    expect(state.isSelectedToday, isTrue);
  });

  test('refreshToday moves selected today after midnight', () {
    var now = DateTime(2026, 4, 27, 10);
    final container = ProviderContainer(
      overrides: [
        diaryCalendarNowProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      DateTime(2026, 4, 27),
    );

    now = DateTime(2026, 4, 28, 8);
    container.read(diaryCalendarControllerProvider.notifier).refreshToday();
    final state = container.read(diaryCalendarControllerProvider);

    expect(state.today, DateTime(2026, 4, 28));
    expect(state.selectedDay, DateTime(2026, 4, 28));
    expect(state.todayRequest, 1);
    expect(state.isSelectedToday, isTrue);
  });

  test('refreshToday preserves a manually selected non-today day', () {
    var now = DateTime(2026, 4, 27, 10);
    final container = ProviderContainer(
      overrides: [
        diaryCalendarNowProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(diaryCalendarControllerProvider.notifier)
        .selectDay(DateTime(2026, 4, 25, 16));
    now = DateTime(2026, 4, 28, 8);
    container.read(diaryCalendarControllerProvider.notifier).refreshToday();
    final state = container.read(diaryCalendarControllerProvider);

    expect(state.today, DateTime(2026, 4, 28));
    expect(state.selectedDay, DateTime(2026, 4, 25));
    expect(state.todayRequest, 0);
    expect(state.isSelectedToday, isFalse);
  });

  test('copyWith keeps unchanged values and applies overrides', () {
    final state = DiaryCalendarState(
      today: DateTime(2026, 4, 27),
      selectedDay: DateTime(2026, 4, 28),
      todayRequest: 2,
    );

    final copied = state.copyWith(selectedDay: DateTime(2026, 4, 29));

    expect(copied.today, state.today);
    expect(copied.selectedDay, DateTime(2026, 4, 29));
    expect(copied.todayRequest, state.todayRequest);
    expect(copied.isSelectedToday, isFalse);
  });
}
