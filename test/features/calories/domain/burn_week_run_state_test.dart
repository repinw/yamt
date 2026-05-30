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
    expect(state.heartDayKeys, isEmpty);
    expect(state.heartStarBreakDayKeys, isEmpty);
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
      heartDayKeys: <String>['2026-4-22'],
      heartStarBreakDayKeys: <String>['2026-4-22'],
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
    expect(decoded.heartDayKeys, <String>['2026-4-22']);
    expect(decoded.heartStarBreakDayKeys, <String>['2026-4-22']);
    expect(decoded.runLimitWarningThisWeek, isTrue);
    expect(decoded.isHeartDay(DateTime(2026, 4, 22)), isTrue);
  });

  test('canUnmarkHeartDay only allows current run week', () {
    const state = BurnWeekRunState(
      currentWeekStartDayKey: '2026-4-21',
      runWeekNumber: 2,
      starCount: 0,
      heartCount: 0,
      heartCreditKcal: 0,
      starBrokeThisWeek: false,
      missedTrackingThisWeek: false,
      heartDayKeys: <String>[
        '2026-4-20',
        '2026-4-21',
        '2026-4-27',
        '2026-4-28',
      ],
    );

    expect(state.canUnmarkHeartDay(DateTime(2026, 4, 20)), isFalse);
    expect(state.canUnmarkHeartDay(DateTime(2026, 4, 21)), isTrue);
    expect(state.canUnmarkHeartDay(DateTime(2026, 4, 27)), isTrue);
    expect(state.canUnmarkHeartDay(DateTime(2026, 4, 28)), isFalse);
    expect(state.canUnmarkHeartDay(DateTime(2026, 4, 22)), isFalse);
    expect(
      const BurnWeekRunState.initial().canUnmarkHeartDay(
        DateTime(2026, 4, 21),
      ),
      isFalse,
    );
  });

  test('canUseHeartForDay only allows active current run week', () {
    const state = BurnWeekRunState(
      currentWeekStartDayKey: '2026-4-21',
      runWeekNumber: 2,
      starCount: 0,
      heartCount: 1,
      heartCreditKcal: 0,
      starBrokeThisWeek: false,
      missedTrackingThisWeek: false,
      heartDayKeys: <String>['2026-4-22'],
    );
    final today = DateTime(2026, 4, 23);

    expect(
      state.canUseHeartForDay(DateTime(2026, 4, 21), today: today),
      isTrue,
    );
    expect(
      state.canUseHeartForDay(DateTime(2026, 4, 27), today: today),
      isTrue,
    );
    expect(
      state.canUseHeartForDay(DateTime(2026, 4, 20), today: today),
      isFalse,
    );
    expect(
      state.canUseHeartForDay(DateTime(2026, 4, 28), today: today),
      isFalse,
    );
    expect(
      state.canUseHeartForDay(DateTime(2026, 4, 22), today: today),
      isFalse,
    );
    expect(
      state
          .copyWith(heartCount: 0)
          .canUseHeartForDay(
            DateTime(2026, 4, 21),
            today: today,
          ),
      isFalse,
    );
    expect(
      state
          .copyWith(
            runWeekNumber: burnWeekLearningRunWeekNumber,
          )
          .canUseHeartForDay(DateTime(2026, 4, 21), today: today),
      isTrue,
    );
    expect(
      state
          .copyWith(currentWeekStartDayKey: null)
          .canUseHeartForDay(
            DateTime(2026, 4, 21),
            today: today,
          ),
      isFalse,
    );
    expect(
      state
          .copyWith(currentWeekStartDayKey: '2026-4-28')
          .canUseHeartForDay(
            DateTime(2026, 4, 28),
            today: today,
          ),
      isFalse,
    );
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
      heartDayKeys: <String>['2026-4-23'],
      heartStarBreakDayKeys: <String>['2026-4-23'],
      runLimitWarningThisWeek: true,
    );

    expect(updated.currentWeekStartDayKey, isNull);
    expect(updated.lastActiveDayKey, '2026-04-22');
    expect(updated.heartCount, 5);
    expect(updated.starCount, 1);
    expect(updated.heartDayKeys, <String>['2026-4-23']);
    expect(updated.heartStarBreakDayKeys, <String>['2026-4-23']);
    expect(updated.runLimitWarningThisWeek, isTrue);
  });
}
