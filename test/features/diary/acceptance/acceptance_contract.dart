// The seams that the acceptance tests of #911 need and that the app does not
// have yet. The builder gives these exact keys to the widgets named here.
// Nothing in this file is an expectation; the expected texts and numbers are
// in the test files and come from lib/features/diary/CRITERIA.md.
//
// Colours: "red" in the criteria is `Theme.of(context).colorScheme.error`,
// the colour the budget card already uses for the part over the budget. A
// keyed part below is a `Container`, `DecoratedBox` or `ColoredBox` whose
// colour (or `BoxDecoration.color`) the tests read; a dashed or hatched part
// is recognised by its key only.
import 'package:flutter/widgets.dart';

/// The three modes of K2, with the German label the criteria give.
enum WeekBalanceMode {
  /// "Aus".
  off('Aus'),

  /// "Anzeigen".
  show('Anzeigen'),

  /// "Mit Übertrag".
  carryover('Mit Übertrag');

  new(this.label);

  /// German option text from K2.
  final String label;
}

/// Keys of the week card (#911), its menu, and the mode choice in the
/// settings.
abstract final class WeekCardKeys {
  /// The week card between the budget card and the steps card (K14). Holding
  /// it opens [menu] (K1).
  static const card = ValueKey<String>('diary-week-card');

  /// The field of the run's day at [index] (0 = the run's first day).
  static ValueKey<String> day(int index) =>
      ValueKey<String>('diary-week-card-day-$index');

  /// The name under the field at [index] ("Mo", "Heute", …), K15.
  static ValueKey<String> dayName(int index) =>
      ValueKey<String>('diary-week-card-day-name-$index');

  /// The number (or "Pause", "leer") under the field at [index], only while
  /// "Details" is open (K19, K20). Absent when nothing is shown.
  static ValueKey<String> dayNumber(int index) =>
      ValueKey<String>('diary-week-card-day-number-$index');

  /// The frame around the shown day's field (K15, K28); exactly one field
  /// has it as a descendant.
  static const frame = ValueKey<String>('diary-week-card-frame');

  /// The eaten part of a finished day's field, up to that day's budget
  /// (K16). Inside [day].
  static const eatenPart = ValueKey<String>('diary-week-card-eaten');

  /// The part of a finished day's field above that day's budget (K16, K22,
  /// K23). Inside [day]; absent when the day is not over its budget.
  static const overPart = ValueKey<String>('diary-week-card-over');

  /// The fill of a day that was under its budget, shown in the colour of
  /// the weight goal (K22: never red; K23 "Zunehmen": red). Inside [day];
  /// it is the [eatenPart] of that day.
  static const ValueKey<String> underPart = eatenPart;

  /// The empty dashed outline of a coming day (K17). Inside [day].
  static const comingOutline = ValueKey<String>('diary-week-card-coming');

  /// The hatched field of a pause day (K18). Inside [day].
  static const pauseHatch = ValueKey<String>('diary-week-card-pause');

  /// The empty track of an empty day (K25). Inside [day].
  static const emptyTrack = ValueKey<String>('diary-week-card-empty');

  /// The dark piece at the front of a day with less budget (K21). Inside
  /// [day].
  static const debtPiece = ValueKey<String>('diary-week-card-debt');

  /// The dashed extra piece at the end of a day with more budget (K21).
  /// Inside [day].
  static const extraPiece = ValueKey<String>('diary-week-card-extra');

  /// The menu sheet that holding the card opens (K1).
  static const menu = ValueKey<String>('diary-week-card-menu');

  /// The option of [mode], in the card's menu and in the settings (K2, K4).
  /// Tapping it picks the mode; its `Semantics`/`selected` state or a
  /// checked radio marks the picked one (see [modeSelected]).
  static ValueKey<String> modeOption(WeekBalanceMode mode) =>
      ValueKey<String>('week-balance-mode-${mode.name}');

  /// The mark of the selected option, a descendant of exactly one
  /// [modeOption] (K2, K4).
  static const modeSelected = ValueKey<String>('week-balance-mode-selected');

  /// The settings row "Wochenzielbalance", next to "Schritte im Tagebuch",
  /// with the chosen mode as its subtitle (K4). Tapping it opens [menu].
  static const settingsTile = ValueKey<String>('settings-week-balance-tile');
}
