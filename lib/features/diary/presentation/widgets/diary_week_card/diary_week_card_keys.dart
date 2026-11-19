import 'package:material_ui/material_ui.dart';

/// Keys of the diary's week card, for tests.
abstract final class DiaryWeekCardKeys {
  /// The week card between the budget card and the steps card.
  static const card = ValueKey<String>('diary-week-card');

  /// The field of the run's day at [index] (0 is the first day of the run).
  static ValueKey<String> day(int index) =>
      ValueKey<String>('diary-week-card-day-$index');

  /// The name under the field at [index].
  static ValueKey<String> dayName(int index) =>
      ValueKey<String>('diary-week-card-day-name-$index');

  /// The number under the field at [index], with the details open.
  static ValueKey<String> dayNumber(int index) =>
      ValueKey<String>('diary-week-card-day-number-$index');

  /// The frame around the field of the shown day.
  static const frame = ValueKey<String>('diary-week-card-frame');

  /// The eaten part of a day's field, up to that day's budget.
  static const eatenPart = ValueKey<String>('diary-week-card-eaten');

  /// The part of a day's field above that day's budget.
  static const overPart = ValueKey<String>('diary-week-card-over');

  /// The dashed outline of a coming day.
  static const comingOutline = ValueKey<String>('diary-week-card-coming');

  /// The hatching of a pause day.
  static const pauseHatch = ValueKey<String>('diary-week-card-pause');

  /// The empty track of a day without entries.
  static const emptyTrack = ValueKey<String>('diary-week-card-empty');

  /// The dark piece at the front of a day with less budget.
  static const debtPiece = ValueKey<String>('diary-week-card-debt');

  /// The dashed piece at the end of a day with more budget.
  static const extraPiece = ValueKey<String>('diary-week-card-extra');
}
