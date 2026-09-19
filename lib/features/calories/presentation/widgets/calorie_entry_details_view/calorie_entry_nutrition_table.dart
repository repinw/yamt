import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_nutrient_details.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_labels.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

const _kilojoulesPerKilocalorie = 4.184;

/// Nutrition table in the layout of a food label: one row per nutrient, one
/// column per 100 g or ml, and one column for the eaten amount.
///
/// Fat, carbohydrates, and protein use the diary macro colors. Nutrients the
/// food source did not provide are left out. Bundles have no values per 100,
/// so they show only the eaten column.
class CalorieEntryNutritionTable extends StatelessWidget {
  /// Creates the nutrition table.
  const new({required this.entry, super.key});

  /// Entry whose nutrition is shown.
  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final showPer100 = !entry.isBundle;
    final rows = _rows(context, l10n, entry.nutrientDetails);

    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w800,
    );
    final divider = BorderSide(color: colors.outlineVariant);

    TableRow row(List<Widget> cells, {required BorderSide border}) {
      return TableRow(
        decoration: BoxDecoration(border: Border(bottom: border)),
        children: [
          for (final cell in cells)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: cell,
            ),
        ],
      );
    }

    Widget value(String text, TextStyle? style) =>
        Text(text, textAlign: TextAlign.end, style: style);

    return ClipRRect(
      key: CalorieEntryDetailKeys.nutritionStrip,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: ColoredBox(
        color: colors.surfaceContainerHigh,
        child: Table(
          columnWidths: {
            0: const FlexColumnWidth(3),
            1: const FlexColumnWidth(2),
            if (showPer100) 2: const FlexColumnWidth(2),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            row(border: divider.copyWith(width: 2), [
              Text(l10n.caloriesNutritionTableNutrient, style: headerStyle),
              if (showPer100)
                value(
                  l10n.caloriesEntryPer100Label(
                    entry.consumedUnit.localizedName(l10n),
                  ),
                  headerStyle,
                ),
              value(calorieEntryConsumedAmountLabel(l10n, entry), headerStyle),
            ]),
            for (final (index, nutrient) in rows.indexed)
              row(
                border: index == rows.length - 1 ? BorderSide.none : divider,
                [
                  Padding(
                    padding: EdgeInsets.only(
                      left: nutrient.isPart ? AppSpacing.md : 0,
                    ),
                    child: Text(
                      nutrient.label,
                      style: _labelStyle(theme, nutrient),
                    ),
                  ),
                  if (showPer100)
                    value(nutrient.per100, _valueStyle(theme, nutrient)),
                  value(
                    nutrient.eaten,
                    _valueStyle(
                      theme,
                      nutrient,
                    )?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<_NutrientRow> _rows(
    BuildContext context,
    AppLocalizations l10n,
    CalorieNutrientDetails? details,
  ) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final grams = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = 2;
    final whole = NumberFormat.decimalPattern(locale);
    final macroColors = MetricAccentColors.of(context);
    final factor = entry.consumedAmount / 100;

    String gramValue(double value) =>
        '${grams.format(value)} ${l10n.caloriesUnitGram}';
    String energyValue(double kcal) =>
        '${whole.format((kcal * _kilojoulesPerKilocalorie).round())} '
        '${l10n.caloriesUnitKilojoule}\n'
        '${whole.format(kcal.round())} ${l10n.caloriesUnitKcal}';
    _NutrientRow? detail(String label, double? per100, {bool isPart = true}) {
      if (per100 == null) {
        return null;
      }
      return _NutrientRow(
        label: label,
        per100: gramValue(per100),
        eaten: gramValue(per100 * factor),
        isPart: isPart,
      );
    }

    return [
      _NutrientRow(
        label: l10n.caloriesNutritionTableEnergy,
        per100: energyValue(entry.per100Kcal),
        eaten: energyValue(entry.totalKcal),
      ),
      _NutrientRow(
        label: l10n.caloriesFatLabel,
        per100: gramValue(entry.per100Fat),
        eaten: gramValue(entry.totalFat),
        accent: macroColors.fat,
      ),
      ?detail(
        l10n.caloriesNutritionTableSaturatedFat,
        details?.per100SaturatedFat,
      ),
      ?detail(
        l10n.caloriesNutritionTablePolyunsaturatedFat,
        details?.per100PolyunsaturatedFat,
      ),
      _NutrientRow(
        label: l10n.caloriesCarbsLabel,
        per100: gramValue(entry.per100Carbs),
        eaten: gramValue(entry.totalCarbs),
        accent: macroColors.carbs,
      ),
      ?detail(l10n.caloriesNutritionTableSugar, details?.per100Sugar),
      ?detail(
        l10n.caloriesNutritionTableFiber,
        details?.per100Fiber,
        isPart: false,
      ),
      _NutrientRow(
        label: l10n.caloriesProteinLabel,
        per100: gramValue(entry.per100Protein),
        eaten: gramValue(entry.totalProtein),
        accent: macroColors.protein,
      ),
      ?detail(
        l10n.caloriesNutritionTableSalt,
        details?.per100Salt,
        isPart: false,
      ),
    ];
  }

  TextStyle? _labelStyle(ThemeData theme, _NutrientRow nutrient) {
    final colors = theme.colorScheme;
    if (nutrient.isPart) {
      return theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
      );
    }
    return theme.textTheme.bodyMedium?.copyWith(
      color: nutrient.accent ?? colors.onSurface,
      fontWeight: nutrient.accent == null ? FontWeight.w600 : FontWeight.w800,
    );
  }

  TextStyle? _valueStyle(ThemeData theme, _NutrientRow nutrient) {
    final colors = theme.colorScheme;
    if (nutrient.isPart) {
      return theme.textTheme.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
      );
    }
    return theme.textTheme.bodyMedium?.copyWith(
      color: nutrient.accent ?? colors.onSurface,
    );
  }
}

class _NutrientRow {
  const new({
    required this.label,
    required this.per100,
    required this.eaten,
    this.accent,
    this.isPart = false,
  });

  final String label;
  final String per100;
  final String eaten;

  /// Diary macro color of the row, or `null` for a plain row.
  final Color? accent;

  /// Whether the row is a muted, indented line such as "of which sugars".
  final bool isPart;
}
