import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';

/// Keys of the diary budget card, for tests.
abstract final class DiaryBudgetCardKeys {
  /// The card.
  static const card = ValueKey<String>('diary-budget-card');

  /// The "Details" chip.
  static const detailsChip = ValueKey<String>('diary-budget-details-chip');

  /// The "Nach Plan" chip.
  static const afterPlanChip = ValueKey<String>('diary-budget-after-plan-chip');

  /// The "Übrig" or, when [eaten], the "Gegessen" segment.
  static ValueKey<String> viewSegment({required bool eaten}) =>
      ValueKey<String>('diary-budget-view-${eaten ? 'eaten' : 'left'}');

  /// The training or pause button of [type].
  static ValueKey<String> dayTypeButton(DiaryDayType type) =>
      ValueKey<String>('diary-budget-day-type-${type.name}');

  /// The big kcal number, or the pause word.
  static const kcalValue = ValueKey<String>('diary-budget-kcal-value');

  /// The words under the big number.
  static const kcalUnit = ValueKey<String>('diary-budget-kcal-unit');

  /// Eaten of target kcal in the details.
  static const kcalTotal = ValueKey<String>('diary-budget-kcal-total');

  /// The grams left of [kind].
  static ValueKey<String> macroValue(DiaryBudgetMacroKind kind) =>
      ValueKey<String>('diary-budget-macro-${kind.name}');

  /// The eaten and target grams of [kind], with details.
  static ValueKey<String> macroTotal(DiaryBudgetMacroKind kind) =>
      ValueKey<String>('diary-budget-macro-total-${kind.name}');

  /// The ledger.
  static const ledger = ValueKey<String>('diary-budget-ledger');

  /// The total row of the ledger.
  static const ledgerTotal = ValueKey<String>('diary-budget-ledger-total');

  /// The link that opens the budget sheet.
  static const allDaysLink = ValueKey<String>('diary-budget-all-days');

  /// The week strip.
  static const weekStrip = ValueKey<String>('diary-budget-week-strip');

  /// The day of the week strip at [index], from the run start.
  static ValueKey<String> weekDay(int index) =>
      ValueKey<String>('diary-budget-week-day-$index');

  /// The button that closes the day before.
  static const closePreviousDay = ValueKey<String>(
    'diary-budget-close-previous-day',
  );

  /// The button that shows the closed day before and opens it again.
  static const reopenPreviousDay = ValueKey<String>(
    'diary-budget-reopen-previous-day',
  );

  /// The note of a day that does not count yet.
  static const notCountingNote = ValueKey<String>(
    'diary-budget-not-counting-note',
  );
}
