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
/// [unknownEaten] is given: then a nutrient with a per-100 value, or with a
/// value in [listed], shows [unknownEaten] for each missing value. The
/// values of the nutrients in [atLeast] are a minimum and are marked as one,
/// such as "mind. 2 g".
List<NutritionFactsRow> nutritionFactsRows(
  BuildContext context, {
  required NutritionFacts eaten,
  NutritionFacts? per100,
  String? unknownEaten,
  NutritionFacts? listed,
  Set<Nutrient> atLeast = const {},
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

  NutritionFactsRow? row(
    String label,
    Nutrient nutrient, {
    String Function(double value)? format,
    Color? accent,
    bool isPart = false,
  }) {
    String formatValue(double value) {
      final text = (format ?? gramValue)(value);
      if (!atLeast.contains(nutrient)) {
        return text;
      }
      // No-break spaces keep a value and its unit together when the
      // minimum wraps in the narrow column.
      return l10n.caloriesNutritionTableAtLeast(text.replaceAll(' ', '\u00A0'));
    }

    final eatenValue = nutrient.of(eaten);
    final per100Value = per100 == null ? null : nutrient.of(per100);
    final isListed = listed != null && nutrient.of(listed) != null;
    final eatenText = eatenValue == null
        ? (per100Value == null && !isListed ? null : unknownEaten)
        : formatValue(eatenValue);
    if (eatenText == null) {
      return null;
    }
    return NutritionFactsRow(
      label: label,
      per100: per100Value == null
          ? (per100 != null && isListed ? unknownEaten : null)
          : formatValue(per100Value),
      eaten: eatenText,
      accent: accent,
      isPart: isPart,
    );
  }

  return [
    ?row(l10n.caloriesNutritionTableEnergy, Nutrient.kcal, format: energyValue),
    ?row(l10n.caloriesFatLabel, Nutrient.fat, accent: macroColors.fat),
    ?row(
      l10n.caloriesNutritionTableSaturatedFat,
      Nutrient.saturatedFat,
      isPart: true,
    ),
    ?row(
      l10n.caloriesNutritionTablePolyunsaturatedFat,
      Nutrient.polyunsaturatedFat,
      isPart: true,
    ),
    ?row(l10n.caloriesCarbsLabel, Nutrient.carbs, accent: macroColors.carbs),
    ?row(l10n.caloriesNutritionTableSugar, Nutrient.sugar, isPart: true),
    ?row(l10n.caloriesNutritionTableFiber, Nutrient.fiber),
    ?row(
      l10n.caloriesProteinLabel,
      Nutrient.protein,
      accent: macroColors.protein,
    ),
    ?row(l10n.caloriesNutritionTableSalt, Nutrient.salt),
  ];
}
