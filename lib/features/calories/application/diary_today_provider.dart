import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';

part 'diary_today_provider.g.dart';

/// Today's diary day from [clockProvider]. It moves on when
/// [DiaryToday.refresh] reads the clock again, at midnight and when the app
/// resumes.
@Riverpod(keepAlive: true)
class DiaryToday extends _$DiaryToday {
  @override
  DateTime build() => normalizeLocalDay(ref.watch(clockProvider)());

  /// Reads the clock again and moves today on when the day changed.
  void refresh() {
    final today = normalizeLocalDay(ref.read(clockProvider)());
    if (today != state) {
      state = today;
    }
  }

  /// The time from now until the next day starts.
  Duration untilNextDay() {
    final now = ref.read(clockProvider)();
    return nextLocalDay(normalizeLocalDay(now)).difference(now);
  }
}
