import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

void main() {
  test('initial state uses expected defaults', () {
    const state = BurnWeekRunState.initial();

    expect(state.currentWeekStartDayKey, isNull);
    expect(state.lastActiveDayKey, isNull);
    expect(state.runWeekNumber, 1);
    expect(state.starCount, 0);
    expect(state.starBrokeThisWeek, isFalse);
    expect(state.missedTrackingThisWeek, isFalse);
    expect(state.runLimitWarningThisWeek, isFalse);
  });

  test('toJson and fromJson round-trip values', () {
    const state = BurnWeekRunState(
      currentWeekStartDayKey: '2026-04-21',
      runWeekNumber: 4,
      starCount: 3,
      starBrokeThisWeek: true,
      missedTrackingThisWeek: true,
      runLimitWarningThisWeek: true,
    );

    final decoded = BurnWeekRunState.fromJson(state.toJson());

    expect(decoded.currentWeekStartDayKey, '2026-04-21');
    expect(decoded.lastActiveDayKey, isNull);
    expect(decoded.runWeekNumber, 4);
    expect(decoded.starCount, 3);
    expect(decoded.starBrokeThisWeek, isTrue);
    expect(decoded.missedTrackingThisWeek, isTrue);
    expect(decoded.runLimitWarningThisWeek, isTrue);
  });

  test('copyWith can clear week key with explicit null', () {
    const state = BurnWeekRunState(
      currentWeekStartDayKey: '2026-04-21',
      runWeekNumber: 2,
      starCount: 1,
      starBrokeThisWeek: false,
      missedTrackingThisWeek: false,
    );

    final updated = state.copyWith(
      currentWeekStartDayKey: null,
      lastActiveDayKey: '2026-04-22',
      runLimitWarningThisWeek: true,
    );

    expect(updated.currentWeekStartDayKey, isNull);
    expect(updated.lastActiveDayKey, '2026-04-22');
    expect(updated.starCount, 1);
    expect(updated.runLimitWarningThisWeek, isTrue);
  });
}
