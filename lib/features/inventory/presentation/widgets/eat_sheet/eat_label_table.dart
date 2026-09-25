import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Nutrition table drawn like a food label: a framed box, a heavy rule
/// under the header and under the energy row.
class EatLabelTable extends StatelessWidget {
  /// Creates the label table.
  const new({
    required this.rows,
    required this.eatenHeader,
    this.per100Header,
    super.key,
  });

  /// Nutrient rows, energy first.
  final List<NutritionFactsRow> rows;

  /// Header of the eaten column.
  final String eatenHeader;

  /// Header of the per-100 column. The column is hidden when null.
  final String? per100Header;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final per100 = per100Header;
    final headerStyle = textTheme.labelSmall?.copyWith(
      fontFamily: AppFonts.mono,
      fontWeight: FontWeight.w700,
      color: colors.ink,
    );

    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colors.ink,
                  width: AppFoodLabel.labelHeaderRule,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      l10n.eatPageNutritionTitle,
                      style: textTheme.titleLarge?.copyWith(
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                        height: 1,
                      ),
                    ),
                  ),
                  if (per100 != null)
                    SizedBox(
                      width: AppFoodLabel.per100Column,
                      child: Text(
                        per100,
                        textAlign: TextAlign.end,
                        style: headerStyle,
                      ),
                    ),
                  SizedBox(
                    width: AppFoodLabel.eatenColumn,
                    child: Text(
                      eatenHeader,
                      textAlign: TextAlign.end,
                      style: headerStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final (index, row) in rows.indexed)
            _LabelRow(
              row: row,
              showPer100: per100 != null,
              bottom: _bottomRule(colors, index),
            ),
        ],
      ),
    );
  }

  BorderSide _bottomRule(FoodLabelColors colors, int index) {
    if (index == rows.length - 1) {
      return BorderSide.none;
    }
    if (index == 0) {
      return BorderSide(color: colors.ink, width: AppFoodLabel.labelEnergyRule);
    }
    if (rows[index + 1].isPart) {
      return BorderSide(color: colors.rule);
    }
    return BorderSide(color: colors.ink);
  }
}

class _LabelRow extends StatelessWidget {
  const new({
    required this.row,
    required this.showPer100,
    required this.bottom,
  });

  final NutritionFactsRow row;
  final bool showPer100;
  final BorderSide bottom;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final color = row.accent ?? (row.isPart ? colors.muted : colors.ink);
    final base = (row.isPart ? textTheme.labelMedium : textTheme.bodySmall)
        ?.copyWith(fontFamily: AppFonts.mono, color: color);
    final per100 = row.per100;

    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: bottom)),
      child: Padding(
        padding: EdgeInsets.only(
          left: row.isPart ? AppSpacing.md : 0,
          top: row.isPart ? AppSpacing.xxs : AppSpacing.xs,
          bottom: row.isPart ? AppSpacing.xxs : AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                row.label,
                style: base?.copyWith(
                  fontWeight: row.isPart
                      ? FontWeight.w400
                      : row.accent == null
                      ? FontWeight.w500
                      : FontWeight.w700,
                ),
              ),
            ),
            if (showPer100)
              SizedBox(
                width: AppFoodLabel.per100Column,
                child: Text(
                  per100 ?? '',
                  textAlign: TextAlign.end,
                  style: base,
                ),
              ),
            SizedBox(
              width: AppFoodLabel.eatenColumn,
              child: Text(
                row.eaten,
                textAlign: TextAlign.end,
                style: base?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
