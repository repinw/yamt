import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/core/widgets/macro_grams.dart';
import 'package:yamt/features/inventory/domain/recipe_estimate.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// "Nährwerte je Zutat" under the ingredients: folded, it opens a small
/// table with the kcal, protein, carbohydrates and fat of each ingredient,
/// for all [portions] together. The macros are in their colors on the
/// numbers only; the labels stand in the header, beside "Für 4 Portionen".
class RecipeLineNutritionSection extends StatefulWidget {
  /// Creates the section for [rows], one per ingredient, sized for
  /// [portions].
  const new({required this.rows, required this.portions, super.key});

  /// Key of the row that opens and folds the table.
  static const toggleKey = ValueKey<String>('recipe-line-nutrition');

  /// Key of the table.
  static const tableKey = ValueKey<String>('recipe-line-nutrition-table');

  /// The food and nutrition of each ingredient, in the recipe's order.
  final List<({String food, RecipeLineNutrition nutrition})> rows;

  /// The portions that [rows] are sized for.
  final int portions;

  @override
  State<RecipeLineNutritionSection> createState() =>
      _RecipeLineNutritionSectionState();
}

class _RecipeLineNutritionSectionState
    extends State<RecipeLineNutritionSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.rule)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            expanded: _open,
            child: AppInkWell(
              key: RecipeLineNutritionSection.toggleKey,
              onTap: () => setState(() => _open = !_open),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: AppGraphit.buttonHeight,
                ),
                child: Row(
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.recipeLineNutritionTitle,
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      _open
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: AppGraphit.toolIcon,
                      color: colors.muted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _Table(
                key: RecipeLineNutritionSection.tableKey,
                rows: widget.rows,
                portions: widget.portions,
              ),
            ),
        ],
      ),
    );
  }
}

class _Table extends StatelessWidget {
  const new({required this.rows, required this.portions, super.key});

  final List<({String food, RecipeLineNutrition nutrition})> rows;
  final int portions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final macros = MacroGrams.textColors(context);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final numberStyle = textTheme.bodySmall?.copyWith(
      color: colors.ink,
      fontFamily: AppFonts.mono,
      fontWeight: FontWeight.w600,
    );
    final headerStyle = textTheme.labelSmall?.copyWith(
      color: colors.muted,
      fontFamily: AppFonts.mono,
    );
    Widget cell(String text, TextStyle? style) => Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(text, textAlign: TextAlign.end, style: style),
    );

    return Table(
      columnWidths: const {0: FlexColumnWidth()},
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Text(
                l10n.recipeLineNutritionPortions(portions),
                style: headerStyle,
              ),
            ),
            cell(l10n.caloriesUnitKcal, headerStyle),
            cell(l10n.caloriesProteinShortLetter, headerStyle),
            cell(l10n.macroGramsCarbsShort, headerStyle),
            cell(l10n.caloriesFatShortLetter, headerStyle),
          ],
        ),
        for (final (:food, :nutrition) in rows)
          TableRow(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.rule)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  food,
                  style: textTheme.bodyMedium?.copyWith(color: colors.ink),
                ),
              ),
              cell(number.format(nutrition.kcal.round()), numberStyle),
              for (final (grams, color) in [
                (nutrition.protein, macros.protein),
                (nutrition.carbs, macros.carbs),
                (nutrition.fat, macros.fat),
              ])
                cell(
                  number.format(grams.round()),
                  numberStyle?.copyWith(color: color),
                ),
            ],
          ),
      ],
    );
  }
}
