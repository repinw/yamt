import 'package:intl/intl.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/l10n/meal_type_l10n.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/data_export/domain/data_export_report.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Placeholder for a value the export does not have.
const String dataExportMissingValue = '–';

/// Localized words and number formats that every export file shares.
class DataExportLabels {
  /// Creates labels for [l10n] in [locale].
  new(this.l10n, String locale)
    : _date = DateFormat.yMd(locale),
      _weekdayDate = DateFormat.yMMMEd(locale),
      _whole = NumberFormat('#,##0', locale),
      _oneDecimal = NumberFormat('#,##0.0', locale),
      _signedOneDecimal = NumberFormat('+#,##0.0;-#,##0.0', locale);

  /// The strings.
  final AppLocalizations l10n;

  final DateFormat _date;
  final DateFormat _weekdayDate;
  final NumberFormat _whole;
  final NumberFormat _oneDecimal;
  final NumberFormat _signedOneDecimal;

  /// A day as a short date.
  String date(DateTime day) => _date.format(day);

  /// A day with its weekday.
  String weekdayDate(DateTime day) => _weekdayDate.format(day);

  /// A rounded number, or [dataExportMissingValue].
  String whole(double? value) =>
      value == null ? dataExportMissingValue : _whole.format(value.round());

  /// A number with one decimal, or [dataExportMissingValue].
  String oneDecimal(double? value) =>
      value == null ? dataExportMissingValue : _oneDecimal.format(value);

  /// A change with its sign and one decimal.
  String signedOneDecimal(double value) => _signedOneDecimal.format(value);

  /// Name of [type].
  String dayType(DiaryDayType type) => switch (type) {
    DiaryDayType.training => l10n.diaryDayTypeTraining,
    DiaryDayType.normal => l10n.diaryDayTypeNormal,
    DiaryDayType.pause => l10n.diaryDayTypePause,
  };

  /// Name of [mode].
  String goalMode(CalorieGoalMode? mode) => switch (mode) {
    CalorieGoalMode.lose => l10n.caloriesCalculatorGoalModeLose,
    CalorieGoalMode.maintain => l10n.caloriesCalculatorGoalModeMaintain,
    CalorieGoalMode.gain => l10n.caloriesCalculatorGoalModeGain,
    null => dataExportMissingValue,
  };

  /// Name of [meal].
  String meal(MealType meal) => meal.localizedName(l10n);

  /// The eaten amount of [entry] with its unit, such as "80 g".
  String amount(CalorieEntry entry) {
    final value = oneDecimalTrimmed(entry.consumedAmount);
    return '$value ${entry.consumedUnit.jsonValue}';
  }

  /// A number with one decimal, without a trailing ",0".
  String oneDecimalTrimmed(double value) =>
      value == value.roundToDouble() ? whole(value) : oneDecimal(value);

  /// Name of [entry] on one line, with its brand unless [withBrand] is
  /// false, marked while its nutrition is still open.
  String foodName(CalorieEntry entry, {bool withBrand = true}) {
    final name = oneLine(entry.name);
    final named = switch (entry.brand) {
      final brand? when withBrand && oneLine(brand).isNotEmpty =>
        '$name (${oneLine(brand)})',
      _ => name,
    };
    return entry.nutritionPending ? l10n.dataExportFoodPending(named) : named;
  }

  /// [text] with every run of whitespace, line breaks too, as one space.
  static String oneLine(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// One goal of the export in a sentence.
  String goalLine(DataExportGoal goal) => l10n.dataExportGoalLine(
    goal.number,
    goalMode(goal.goalMode),
    date(goal.startDay),
    switch (goal.endDay) {
      final end? => date(end),
      null => l10n.dataExportGoalRunning,
    },
    oneDecimal(goal.startWeightKg),
    oneDecimal(goal.targetWeightKg),
    oneDecimal(goal.speedKgPerWeek),
    whole(goal.baseKcal),
  );

  /// The parts of the day of [report] in a sentence.
  String mealShares(DataExportReport report) => l10n.dataExportMealShares(
    [
      for (final (index, meal) in MealType.sectionOrder.indexed)
        l10n.dataExportMealShare(
          this.meal(meal),
          report.mealSharePercents[index],
        ),
    ].join(l10n.dataExportListSeparator),
  );

  /// File name of [report] in [extension], such as
  /// `yamt-2026-10-06-2026-11-01.txt`.
  static String fileName(DataExportReport report, String extension) {
    final format = DateFormat('yyyy-MM-dd');
    return 'yamt-${format.format(report.from)}-${format.format(report.to)}'
        '.$extension';
  }
}
