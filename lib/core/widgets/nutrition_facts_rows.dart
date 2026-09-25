import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _kilojoulesPerKilocalorie = 4.184;

/// One nutrient line of a food label table.
class NutritionFactsRow {
  /// Creates a row.
  const new({
    required this.label,
    required this.per100,
    required this.eaten,
    this.accent,
    this.isPart = false,
  });

  /// Nutrient name.
  final String label;

  /// Formatted value per 100 g or ml, or null without one.
  final String? per100;

  /// Formatted value of the eaten amount.
  final String eaten;

  /// Diary macro color of the row, or null for a plain row.
  final Color? accent;

  /// Whether the row is a muted, indented line such as "of which sugars".
  final bool isPart;
}

/// The food label rows for [eaten] and optional [per100] values, in label
/// order. Nutrients without an eaten value are left out, unless
/// [unknownEaten] is given: then a nutrient with a per-100 value shows
/// [unknownEaten] as its eaten value.
List<NutritionFactsRow> nutritionFactsRows(
  BuildContext context, {
  required NutritionFacts eaten,
  NutritionFacts? per100,
  String? unknownEaten,
}) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toLanguageTag();
  final grams = NumberFormat.decimalPattern(locale)..maximumFractionDigits = 2;
  final whole = NumberFormat.decimalPattern(locale);
  final macroColors = MetricAccentColors.of(context);

  String gramValue(double value) =>
      '${grams.format(value)} ${l10n.caloriesUnitGram}';
  String energyValue(double kcal) =>
      '${whole.format((kcal * _kilojoulesPerKilocalorie).round())} '
      '${l10n.caloriesUnitKilojoule}\n'
      '${whole.format(kcal.round())} ${l10n.caloriesUnitKcal}';

  NutritionFactsRow? nutrient(
    String label,
    double? Function(NutritionFacts facts) read, {
    String Function(double value)? format,
    Color? accent,
    bool isPart = false,
  }) {
    final eatenValue = read(eaten);
    final formatValue = format ?? gramValue;
    final per100Value = per100 == null ? null : read(per100);
    final eatenText = eatenValue == null
        ? (per100Value == null ? null : unknownEaten)
        : formatValue(eatenValue);
    if (eatenText == null) {
      return null;
    }
    return NutritionFactsRow(
      label: label,
      per100: per100Value == null ? null : formatValue(per100Value),
      eaten: eatenText,
      accent: accent,
      isPart: isPart,
    );
  }

  return [
    ?nutrient(
      l10n.caloriesNutritionTableEnergy,
      (facts) => facts.kcal,
      format: energyValue,
    ),
    ?nutrient(
      l10n.caloriesFatLabel,
      (facts) => facts.fat,
      accent: macroColors.fat,
    ),
    ?nutrient(
      l10n.caloriesNutritionTableSaturatedFat,
      (facts) => facts.saturatedFat,
      isPart: true,
    ),
    ?nutrient(
      l10n.caloriesNutritionTablePolyunsaturatedFat,
      (facts) => facts.polyunsaturatedFat,
      isPart: true,
    ),
    ?nutrient(
      l10n.caloriesCarbsLabel,
      (facts) => facts.carbs,
      accent: macroColors.carbs,
    ),
    ?nutrient(
      l10n.caloriesNutritionTableSugar,
      (facts) => facts.sugar,
      isPart: true,
    ),
    ?nutrient(l10n.caloriesNutritionTableFiber, (facts) => facts.fiber),
    ?nutrient(
      l10n.caloriesProteinLabel,
      (facts) => facts.protein,
      accent: macroColors.protein,
    ),
    ?nutrient(l10n.caloriesNutritionTableSalt, (facts) => facts.salt),
  ];
}
