import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';
import 'package:yamt/features/inventory/presentation/inventory_amount_unit_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_framed_box.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Collapsible list of the ingredients bound to a prepared meal.
class EatComponentsList extends StatefulWidget {
  /// Creates the list for [components] with their eaten amounts.
  const new({required this.components, super.key});

  /// Header that opens and closes the list.
  static const toggleKey = Key('eat_sheet_components_toggle');

  /// Bound ingredients with the amounts being eaten.
  final List<({PreparedMealComponent component, double amount})> components;

  @override
  State<EatComponentsList> createState() => _EatComponentsListState();
}

class _EatComponentsListState extends State<EatComponentsList> {
  var _isExpanded = false;

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
            for (final (:component, :amount) in widget.components)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.rule)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    spacing: AppSpacing.md,
                    children: [
                      Expanded(child: Text(component.name, style: mono)),
                      Text(
                        l10n.inventoryEatSheetAmountWithUnit(
                          formatInventoryNutritionValue(amount),
                          component.usedUnit.localizedName(l10n),
                        ),
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
