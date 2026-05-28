import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/calories/domain/calorie_weekly_checkin.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

const _dayKeyListEquality = ListEquality<String>();
const _storedGoalListEquality = ListEquality<double>();

/// Weekly learned TDEE target that is stable until the next boundary.
class DailyLearnedTdeeGoalData {
  /// Creates learned TDEE goal data.
  const DailyLearnedTdeeGoalData({
    required this.measured,
    required this.calculatedBaseTdeeKcal,
    required this.newBaseGoalKcal,
    required this.averageCreditedActivityKcal,
  });

  /// The measured TDEE before EMA smoothing.
  final CalorieMeasuredTdeeCalculation measured;

  /// The smoothed learned Base-TDEE.
  final double calculatedBaseTdeeKcal;

  /// The capped base target goal.
  final double newBaseGoalKcal;

  /// Average credited activity kcal for the learned window.
  final double averageCreditedActivityKcal;

  /// Backwards-compatible label while old UI copy is renamed.
  double get calculatedTrueTdeeKcal => calculatedBaseTdeeKcal;

  /// Backwards-compatible label for base goal.
  double get newGoalKcal => newBaseGoalKcal;

  /// Backwards-compatible label for credited activity average.
  double get averageActiveKcal => averageCreditedActivityKcal;
}

/// One day request for learned TDEE batch resolution.
@immutable
class DailyLearnedTdeeGoalDayRequest {
  /// Creates request for one day.
  const DailyLearnedTdeeGoalDayRequest({
    required this.day,
    required this.storedGoalKcal,
  });

  /// Diary day.
  final DateTime day;

  /// Stored kcal goal for [day].
  final double storedGoalKcal;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DailyLearnedTdeeGoalDayRequest &&
        isSameDiaryDay(other.day, day) &&
        other.storedGoalKcal == storedGoalKcal;
  }

  @override
  int get hashCode => Object.hash(diaryDayKey(day), storedGoalKcal);
}

/// Stable request key for learned TDEE batch resolution.
@immutable
class DailyLearnedTdeeGoalDaysRequest {
  /// Creates request from day goals.
  factory DailyLearnedTdeeGoalDaysRequest({
    required DateTime today,
    required Iterable<DailyLearnedTdeeGoalDayRequest> days,
  }) {
    final daysByKey = <String, DailyLearnedTdeeGoalDayRequest>{};
    for (final request in days) {
      final normalizedDay = normalizeDiaryDay(request.day);
      daysByKey[diaryDayKey(normalizedDay)] = DailyLearnedTdeeGoalDayRequest(
        day: normalizedDay,
        storedGoalKcal: request.storedGoalKcal,
      );
    }

    final normalizedToday = normalizeDiaryDay(today);
    return DailyLearnedTdeeGoalDaysRequest._(
      normalizedToday,
      List<DailyLearnedTdeeGoalDayRequest>.unmodifiable(daysByKey.values),
      List<String>.unmodifiable(daysByKey.keys),
      List<double>.unmodifiable(
        daysByKey.values.map((request) => request.storedGoalKcal),
      ),
    );
  }

  const DailyLearnedTdeeGoalDaysRequest._(
    this.today,
    this.days,
    this._dayKeys,
    this._storedGoals,
  );

  /// Normalized today.
  final DateTime today;

  /// Day requests.
  final List<DailyLearnedTdeeGoalDayRequest> days;

  final List<String> _dayKeys;
  final List<double> _storedGoals;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is DailyLearnedTdeeGoalDaysRequest &&
        isSameDiaryDay(other.today, today) &&
        _dayKeyListEquality.equals(_dayKeys, other._dayKeys) &&
        _storedGoalListEquality.equals(_storedGoals, other._storedGoals);
  }

  @override
  int get hashCode {
    return Object.hash(
      diaryDayKey(today),
      _dayKeyListEquality.hash(_dayKeys),
      _storedGoalListEquality.hash(_storedGoals),
    );
  }
}
