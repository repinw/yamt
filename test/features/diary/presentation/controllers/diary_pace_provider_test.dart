import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_shares_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_meal_times_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_marker_controller.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_pace_provider.dart';

import '../../../../helpers/memory_app_preferences.dart';

/// These run as widget tests for their fake clock only: the provider ticks
/// with a timer, and a test fails when its timer is still pending at the end.
void main() {
  final today = DateTime(2026, 4, 27);
  // What the clock shows; a test moves it on.
  late DateTime now;

  setUp(() => now = DateTime(2026, 4, 27, 12));

  // Riverpod rebuilds and disposes providers in timers of zero length.
  Future<void> settle(WidgetTester tester) => tester.pump(Duration.zero);

  ProviderContainer containerWith({bool markerOn = true}) {
    final container = ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          MemoryAppPreferences(
            initialInts: {if (markerOn) 'diary_pace_marker_v1': 1},
          ),
        ),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Listens to the pace share of [day] as a card on screen does, and
  /// collects every value it takes.
  List<double?> watchPace(ProviderContainer container, DateTime day) {
    final values = <double?>[];
    container.listen(
      diaryPaceShareProvider(day),
      (_, next) => values.add(next),
      fireImmediately: true,
    );
    return values;
  }

  testWidgets('is null while the marker is off', (tester) async {
    final container = containerWith(markerOn: false);

    expect(container.read(diaryPaceShareProvider(today)), isNull);

    await settle(tester);
  });

  testWidgets('is null on any day but today, also with the marker on', (
    tester,
  ) async {
    final container = containerWith();

    for (final day in [DateTime(2026, 4, 26), DateTime(2026, 4, 28)]) {
      expect(
        container.read(diaryPaceShareProvider(day)),
        isNull,
        reason: '$day',
      );
    }

    await settle(tester);
  });

  testWidgets('is the share due by now on today', (tester) async {
    final container = containerWith();
    final values = watchPace(container, today);

    // 12:00 is three quarters through lunch's window from 9:00 to 13:00.
    expect(values, [closeTo(0.5125, 1e-9)]);

    container.dispose();
  });

  for (final (time, share) in [
    (DateTime(2026, 4, 27, 5, 30), 0.0),
    (DateTime(2026, 4, 27, 6), 0.0),
    (DateTime(2026, 4, 27, 22), 1.0),
  ]) {
    testWidgets('is $share at $time, before the day starts or after its '
        'last meal', (tester) async {
      final container = containerWith();
      now = time;

      expect(watchPace(container, today), [share]);

      container.dispose();
    });
  }

  testWidgets('moves on with every minute the clock shows', (tester) async {
    final container = containerWith();
    now = DateTime(2026, 4, 27, 7, 29, 30);
    final values = watchPace(container, today);
    // 7:29 is 89 of the 180 minutes of breakfast's window.
    final before = closeTo(25 * 89 / 180 / 100, 1e-9);
    expect(values, [before]);

    // The next minute starts in 30 seconds.
    now = DateTime(2026, 4, 27, 7, 30);
    await tester.pump(const Duration(seconds: 29));
    expect(values, [before]);
    await tester.pump(const Duration(seconds: 1));
    expect(values, [before, closeTo(0.125, 1e-9)]);

    // On the full minute it waits a whole one.
    now = DateTime(2026, 4, 27, 7, 31);
    await tester.pump(const Duration(seconds: 59));
    expect(values, hasLength(2));
    await tester.pump(const Duration(seconds: 1));
    expect(values, hasLength(3));
    expect(values.last, closeTo(25 * 91 / 180 / 100, 1e-9));

    container.dispose();
  });

  testWidgets('follows the parts of the day and the times the user sets', (
    tester,
  ) async {
    final container = containerWith();
    now = DateTime(2026, 4, 27, 9);
    final values = watchPace(container, today);
    expect(values, [closeTo(0.25, 1e-9)]);

    await container
        .read(diaryMealSharesControllerProvider.notifier)
        .select(const DiaryMealShares([50, 20, 20, 10]));
    await settle(tester);
    expect(values.last, closeTo(0.5, 1e-9));

    // The day starts at 10:00, so nothing is due at 9:00 yet.
    await container
        .read(diaryMealTimesControllerProvider.notifier)
        .select(DiaryMealTimes.standard.withStart(10 * 60));
    await settle(tester);
    expect(values.last, 0);

    container.dispose();
  });

  testWidgets('is null from the moment the marker is switched off and back '
      'when it is switched on', (tester) async {
    final container = containerWith();
    final values = watchPace(container, today);
    final marker = container.read(diaryPaceMarkerControllerProvider.notifier);

    await marker.show(visible: false);
    await settle(tester);
    expect(values, [closeTo(0.5125, 1e-9), null]);

    // Off, it no longer asks the clock: no timer is left to run.
    await tester.pump(const Duration(minutes: 5));
    expect(values, hasLength(2));

    await marker.show(visible: true);
    await settle(tester);
    expect(values, [closeTo(0.5125, 1e-9), null, closeTo(0.5125, 1e-9)]);

    container.dispose();
  });

  testWidgets('is null for a day that is over once today moves on', (
    tester,
  ) async {
    final container = containerWith();
    now = DateTime(2026, 4, 27, 23, 59, 50);
    final values = watchPace(container, today);
    expect(values, [1.0]);

    now = DateTime(2026, 4, 28, 0, 0, 5);
    container.read(diaryTodayProvider.notifier).refresh();
    await settle(tester);

    expect(values, [1.0, null]);
    // The new day's card has it from its start.
    final tomorrow = watchPace(container, DateTime(2026, 4, 28));
    expect(tomorrow, [0.0]);

    container.dispose();
  });

  testWidgets('ends its minute timer with its last listener', (tester) async {
    final container = containerWith();
    now = DateTime(2026, 4, 27, 9, 0, 45);
    container.listen(diaryPaceShareProvider(today), (_, _) {}).close();
    await settle(tester);

    // The test fails when a timer of the provider is still pending now.
    expect(container.exists(diaryPaceShareProvider(today)), isFalse);
  });
}
