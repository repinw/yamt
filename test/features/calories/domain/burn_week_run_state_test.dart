import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/burn_week_run_state.dart';

void main() {
  test('initial state uses expected defaults', () {
    const state = BurnWeekRunState.initial();

    expect(state.currentWeekStartDayKey, isNull);
    expect(state.lastActiveDayKey, isNull);
    expect(state.runWeekNumber, 1);
    expect(state.starCount, 0);
    expect(state.heartCount, burnWeekInitialHeartCount);
    expect(state.heartCreditKcal, 0);
    expect(state.starBrokeThisWeek, isFalse);
    expect(state.missedTrackingThisWeek, isFalse);
    expect(state.runLimitWarningThisWeek, isFalse);
  });

  test('fromJson ignores entries without current schema', () {
    final state = BurnWeekRunState.fromJson(const <String, dynamic>{
      'run_week_number': 8,
      'star_count': 4,
      'heart_count': 3,
    });

    expect(state.heartCount, burnWeekInitialHeartCount);
    expect(state.runWeekNumber, burnWeekLearningRunWeekNumber);
    expect(state.starCount, 0);
  });

  test('toJson and fromJson round-trip values', () {
    const state = BurnWeekRunState(
      currentWeekStartDayKey: '2026-04-21',
      runWeekNumber: 4,
      starCount: 3,
      heartCount: 3,
      heartCreditKcal: -1400,
      starBrokeThisWeek: true,
      missedTrackingThisWeek: true,
      runLimitWarningThisWeek: true,
    );

    final decoded = BurnWeekRunState.fromJson(state.toJson());

    expect(state.toJson()['schema_version'], burnWeekRunStateSchemaVersion);
    expect(decoded.currentWeekStartDayKey, '2026-04-21');
    expect(decoded.lastActiveDayKey, isNull);
    expect(decoded.runWeekNumber, 4);
    expect(decoded.starCount, 3);
    expect(decoded.heartCount, 3);
    expect(decoded.heartCreditKcal, -1400);
    expect(decoded.starBrokeThisWeek, isTrue);
    expect(decoded.missedTrackingThisWeek, isTrue);
    expect(decoded.runLimitWarningThisWeek, isTrue);
  });

  test('copyWith can clear week key with explicit null', () {
    const state = BurnWeekRunState(
      currentWeekStartDayKey: '2026-04-21',
      runWeekNumber: 2,
      starCount: 1,
      heartCount: 2,
      heartCreditKcal: 500,
      starBrokeThisWeek: false,
      missedTrackingThisWeek: false,
    );

    final updated = state.copyWith(
      currentWeekStartDayKey: null,
      lastActiveDayKey: '2026-04-22',
      heartCount: 5,
      runLimitWarningThisWeek: true,
    );

    expect(updated.currentWeekStartDayKey, isNull);
    expect(updated.lastActiveDayKey, '2026-04-22');
    expect(updated.heartCount, 5);
    expect(updated.starCount, 1);
    expect(updated.runLimitWarningThisWeek, isTrue);
  });
}
