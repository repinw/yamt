import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';

void main() {
  late DateTime now;
  late ProviderContainer container;

  setUp(() {
    now = DateTime(2026, 10, 8, 22, 30);
    container = ProviderContainer(
      overrides: [clockProvider.overrideWithValue(() => now)],
    );
    addTearDown(container.dispose);
  });

  test('today is the day of the clock', () {
    expect(container.read(diaryTodayProvider), DateTime(2026, 10, 8));
  });

  test('the next day starts at midnight', () {
    expect(
      container.read(diaryTodayProvider.notifier).untilNextDay(),
      const Duration(hours: 1, minutes: 30),
    );
  });

  test('refresh moves today on only when the day changed', () {
    final changes = <DateTime>[];
    container.listen(diaryTodayProvider, (_, today) => changes.add(today));

    now = DateTime(2026, 10, 8, 23, 59);
    container.read(diaryTodayProvider.notifier).refresh();
    now = DateTime(2026, 10, 9, 0, 1);
    container.read(diaryTodayProvider.notifier).refresh();

    expect(changes, [DateTime(2026, 10, 9)]);
  });
}
