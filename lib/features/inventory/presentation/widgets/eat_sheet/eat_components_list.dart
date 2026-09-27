import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/domain/inventory_amount_parser.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// One ingredient line: its name, the amount being eaten, and optionally
/// its energy for that amount.
typedef EatComponentLine = ({
  String name,
  double amount,
  InventoryAmountUnit unit,
  double? kcal,
});

/// Collapsible list of the ingredients of a meal.
class EatComponentsList extends StatefulWidget {
  /// Creates the list for [components] with their eaten amounts.
  const new({
    required this.components,
    this.initiallyExpanded = false,
    super.key,
  });

  /// Header that opens and closes the list.
  static const toggleKey = Key('eat_sheet_components_toggle');

  /// Ingredients with the amounts being eaten.
  final List<EatComponentLine> components;

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
    final mono = textTheme.bodySmall?.copyWith(
      fontFamily: AppFonts.mono,
      color: colors.ink,
    );

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
                        fontFamily: AppFonts.display,
                        fontWeight: FontWeight.w800,
                        color: colors.ink,
                      ),
                    ),
                  ),
                  Text(
                    l10n.preparedMealIngredientsCount(widget.components.length),
                    style: mono?.copyWith(color: colors.muted),
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
          if (_isExpanded)
            for (final (:name, :amount, :unit, :kcal) in widget.components)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.rule)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    spacing: AppSpacing.md,
                    children: [
                      Expanded(child: Text(name, style: mono)),
                      Text(
                        l10n.inventoryEatSheetAmountWithUnit(
                          formatInventoryNutritionValue(amount),
                          unit.localizedName(l10n),
                        ),
                        style: mono?.copyWith(
                          fontWeight: kcal == null ? FontWeight.w700 : null,
                          color: kcal == null ? null : colors.muted,
                        ),
                      ),
                      if (kcal != null)
                        Text(
                          l10n.eatPageKcal(kcal.round()),
                          style: mono?.copyWith(fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
