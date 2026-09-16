import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/diary/application/diary_plan_start_day_provider.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';

ProviderContainer _container({
  required DateTime Function() now,
  DateTime? planStartDay,
}) {
  final container = ProviderContainer(
    overrides: [
      diaryCalendarNowProvider.overrideWithValue(now),
      diaryPlanStartDayProvider.overrideWithValue(planStartDay),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('initial state starts on normalized today', () {
    final container = _container(now: () => DateTime(2026, 4, 27, 10));

    final state = container.read(diaryCalendarControllerProvider);

    expect(state.today, DateTime(2026, 4, 27));
    expect(state.selectedDay, state.today);
    expect(state.isSelectedToday, isTrue);
  });

  test('selectDay normalizes the day and ignores same-day changes', () {
    final container = _container(
      now: () => DateTime(2026, 4, 27, 10),
      planStartDay: DateTime(2026, 4),
    );

    container.read(diaryCalendarControllerProvider.notifier)
      ..selectDay(DateTime(2026, 4, 25, 16, 45))
      ..selectDay(DateTime(2026, 4, 25, 22, 30));

    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      DateTime(2026, 4, 25),
    );
  });

  test('selectDay clamps to plan start and two weeks ahead', () {
    final container = _container(
      now: () => DateTime(2026, 4, 27, 10),
      planStartDay: DateTime(2026, 4, 20),
    );
    final notifier = container.read(diaryCalendarControllerProvider.notifier)
      ..selectDay(DateTime(2026, 3));

    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      DateTime(2026, 4, 20),
    );

    notifier.selectDay(DateTime(2026, 6));
    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      DateTime(2026, 5, 11),
    );
  });

  test('without a plan the user cannot go before today', () {
    final container = _container(now: () => DateTime(2026, 4, 27, 10));

    container
        .read(diaryCalendarControllerProvider.notifier)
        .selectPreviousDay();

    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      DateTime(2026, 4, 27),
    );
    expect(
      container
          .read(diaryCalendarBoundsProvider)
          .canGoBack(
            DateTime(2026, 4, 27),
          ),
      isFalse,
    );
  });

  test('previous and next day step across DST changes', () {
    final container = _container(
      now: () => DateTime(2026, 3, 29, 10),
      planStartDay: DateTime(2026, 3),
    );
    final notifier = container.read(diaryCalendarControllerProvider.notifier)
      ..selectPreviousDay();

    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      DateTime(2026, 3, 28),
    );

    notifier
      ..selectNextDay()
      ..selectNextDay();
    expect(
      container.read(diaryCalendarControllerProvider).selectedDay,
      DateTime(2026, 3, 30),
    );
  });

  test('refreshToday moves selected today after midnight', () {
    var now = DateTime(2026, 4, 27, 10);
    final container = _container(now: () => now);

    expect(
      container.read(diaryCalendarControllerProvider).today,
      DateTime(2026, 4, 27),
    );
    now = DateTime(2026, 4, 28, 8);
    container.read(diaryCalendarControllerProvider.notifier).refreshToday();
    final state = container.read(diaryCalendarControllerProvider);

    expect(state.today, DateTime(2026, 4, 28));
    expect(state.selectedDay, DateTime(2026, 4, 28));
  });

  test('refreshToday preserves a manually selected non-today day', () {
    var now = DateTime(2026, 4, 27, 10);
    final container = _container(
      now: () => now,
      planStartDay: DateTime(2026, 4),
    );

    container
        .read(diaryCalendarControllerProvider.notifier)
        .selectDay(DateTime(2026, 4, 25, 16));
    now = DateTime(2026, 4, 28, 8);
    container.read(diaryCalendarControllerProvider.notifier).refreshToday();
    final state = container.read(diaryCalendarControllerProvider);

    expect(state.today, DateTime(2026, 4, 28));
    expect(state.selectedDay, DateTime(2026, 4, 25));
    expect(state.isSelectedToday, isFalse);
  });

  test('copyWith keeps unchanged values and applies overrides', () {
    final state = DiaryCalendarState(
      today: DateTime(2026, 4, 27),
      selectedDay: DateTime(2026, 4, 28),
    );

    final copied = state.copyWith(selectedDay: DateTime(2026, 4, 29));

    expect(copied.today, state.today);
    expect(copied.selectedDay, DateTime(2026, 4, 29));
    expect(copied.isSelectedToday, isFalse);
  });
}
