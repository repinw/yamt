import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Nutrition table in the layout of a food label: one row per nutrient, an
/// optional column per 100 g or ml, and one column for the eaten amount.
///
/// Fat, carbohydrates, and protein use the diary macro colors. Nutrients
/// without an eaten value are left out.
class NutritionFactsTable extends StatelessWidget {
  /// Creates the nutrition table.
  const new({
    required this.eaten,
    required this.eatenHeader,
    this.per100,
    this.per100Header,
    super.key,
  });

  /// Nutrients of the eaten amount.
  final NutritionFacts eaten;

  /// Header of the eaten column, for example "60 g".
  final String eatenHeader;

  /// Nutrients per 100 g or ml. The column is hidden when null.
  final NutritionFacts? per100;

  /// Header of the per-100 column.
  final String? per100Header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final showPer100 = per100 != null && per100Header != null;
    final rows = nutritionFactsRows(context, eaten: eaten, per100: per100);
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
              if (showPer100) value(per100Header!, headerStyle),
              value(eatenHeader, headerStyle),
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
                    value(nutrient.per100 ?? '', _valueStyle(theme, nutrient)),
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

  TextStyle? _labelStyle(ThemeData theme, NutritionFactsRow nutrient) {
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

  TextStyle? _valueStyle(ThemeData theme, NutritionFactsRow nutrient) {
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
