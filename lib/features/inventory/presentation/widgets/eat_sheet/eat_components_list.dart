import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One ingredient line: its name, the amount being eaten as text, and
/// optionally its energy for that amount.
typedef EatComponentLine = ({String name, String amount, double? kcal});

/// One line of a recipe: the line itself, such as "100 g Reis", the Vorrat
/// items that supply it, or null when none does, the amount and energy they
/// give, and what a tap on it does.
typedef EatRecipeLine = ({
  String line,
  String? items,
  String? amount,
  double? kcal,
  VoidCallback? onTap,
});

/// Text of an ingredient [amount] in [unit], such as "150 g".
String eatComponentAmount(
  AppLocalizations l10n,
  double amount,
  InventoryAmountUnit unit,
) {
  return l10n.inventoryEatSheetAmountWithUnit(
    formatInventoryNutritionValue(amount),
    unit.localizedName(l10n),
  );
}

/// Collapsible list of the ingredients of a meal.
class EatComponentsList extends StatefulWidget {
  /// Creates the list for [components] with their eaten amounts.
  const new({
    required this.components,
    this.initiallyExpanded = false,
    super.key,
  }) : recipeLines = null;

  /// Creates the list for the [recipeLines] of a recipe, with [components]
  /// that no line takes below them.
  const new recipe({
    required List<EatRecipeLine> this.recipeLines,
    this.components = const [],
    this.initiallyExpanded = false,
    super.key,
  });

  /// Header that opens and closes the list.
  static const toggleKey = Key('eat_sheet_components_toggle');

  /// Key of the recipe line at [index].
  static ValueKey<String> recipeLineKey(int index) =>
      ValueKey<String>('eat_sheet_recipe_line_$index');

  /// Ingredients with the amounts being eaten; below [recipeLines], the
  /// ones no line takes.
  final List<EatComponentLine> components;

  /// Lines of a recipe, shown above [components].
  final List<EatRecipeLine>? recipeLines;

  /// Whether the list starts open.
  final bool initiallyExpanded;

  @override
  State<EatComponentsList> createState() => _EatComponentsListState();
}

class _EatComponentsListState extends State<EatComponentsList> {
  late bool _isExpanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final rowStyle = textTheme.bodySmall?.copyWith(color: colors.ink);
    final recipeLines = widget.recipeLines;

    return EatFramedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppInkWell(
            key: EatComponentsList.toggleKey,
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: kMinInteractiveDimension,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.preparedMealIngredientsTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Text(
                    l10n.preparedMealIngredientsCount(
                      (recipeLines?.length ?? 0) + widget.components.length,
                    ),
                    style: rowStyle?.copyWith(color: colors.muted),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.ink,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded && recipeLines != null)
            for (final (index, line) in recipeLines.indexed)
              _EatRecipeLineRow(
                key: EatComponentsList.recipeLineKey(index),
                line: line,
                style: rowStyle,
              ),
          if (_isExpanded)
            for (final (:name, :amount, :kcal) in widget.components)
              _EatComponentRow(
                children: [
                  Expanded(child: Text(name, style: rowStyle)),
                  Text(
                    amount,
                    style: rowStyle?.copyWith(
                      fontWeight: kcal == null ? FontWeight.w700 : null,
                      color: kcal == null ? null : colors.muted,
                    ),
                  ),
                  if (kcal != null)
                    Text(
                      l10n.eatPageKcal(kcal.round()),
                      style: rowStyle?.copyWith(fontWeight: FontWeight.w700),
                    ),
                ],
              ),
        ],
      ),
    );
  }
}

/// A row of the list under a rule.
class _EatComponentRow extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: FoodLabelColors.of(context).rule),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(spacing: AppSpacing.md, children: children),
      ),
    );
  }
}

/// A recipe line over the Vorrat items that supply it, or "fehlt" in the
/// low color, with a chevron when a tap picks another item.
class _EatRecipeLineRow extends StatelessWidget {
  const new({required this.line, required this.style, super.key});

  final EatRecipeLine line;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final (:line, :items, :amount, :kcal, :onTap) = this.line;
    return AppInkWell(
      onTap: onTap,
      child: _EatComponentRow(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line, style: style?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  items ?? l10n.eatPageIngredientMissing,
                  style: style?.copyWith(
                    color: items == null ? colors.low : colors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (amount != null)
            Text(amount, style: style?.copyWith(color: colors.muted)),
          if (kcal != null)
            Text(
              l10n.eatPageKcal(kcal.round()),
              style: style?.copyWith(fontWeight: FontWeight.w700),
            ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: colors.muted),
        ],
      ),
    );
  }
}
