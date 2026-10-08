import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_amount_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_chip.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_count_row.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_inedible_line.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_inline_amount_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_remember_portion.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_ruler.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_text_field.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/inventory_item_eat_sheet_body.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Amount part of the item eat page: the ruler, the piece size, remembered
/// portions, and the inedible share.
class InventoryItemEatAmountSection extends StatelessWidget {
  /// Creates the section for [state].
  const new({
    required this.state,
    required this.controller,
    required this.amountField,
    required this.pieceWeight,
    required this.inedibleAmount,
    required this.onToggleInedible,
    super.key,
  });

  /// Key of the button that takes one counted portion away.
  static const portionDecreaseKey = Key('eat_page_portion_decrease');

  /// Key of the button that adds one counted portion.
  static const portionIncreaseKey = Key('eat_page_portion_increase');

  /// Key of the counted portion count.
  static const portionCountKey = Key('eat_page_portion_count');

  /// Key of the button that takes one package away.
  static const packageDecreaseKey = Key('eat_page_package_decrease');

  /// Key of the button that adds one package.
  static const packageIncreaseKey = Key('eat_page_package_increase');

  /// Key of the package count.
  static const packageCountKey = Key('eat_page_package_count');

  /// The eat page state.
  final InventoryItemEatSheetState state;

  /// The eat page controller.
  final InventoryItemEatSheetController controller;

  /// Field of the amount, in pieces or in the item unit.
  final EatSheetTextField amountField;

  /// Field of one piece's weight.
  final EatSheetTextField pieceWeight;

  /// Field of the inedible share.
  final EatSheetTextField inedibleAmount;

  /// Opens or closes the inedible share.
  final VoidCallback onToggleInedible;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final calculator = state.calculator;
    final units = calculator.availablePortionUnits;
    final selectedSize = state.selectedPieceSize;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EatAmountRuler(
          controller: amountField.controller,
          focusNode: amountField.focusNode,
          unitLabel: state.amountUnit(l10n),
          value: state.amountValue,
          max: state.amountMax,
          step: state.amountStep,
          marks: [
            for (final marker in state.markers)
              EatRulerMark(
                label: state.markLabel(l10n, marker),
                value: marker.value,
                isSelected: state.isMarkerSelected(marker),
                onPressed: () => controller.pickMarker(marker),
              ),
          ],
          allowFractionalInput:
              state.usesPortionMode ||
              calculator.allowsFractionalInventoryAmount ||
              calculator.takesDecimalWeight,
          hint: state.amountHint(l10n),
          errorText: state.amountError(l10n),
          onTextChanged: controller.setAmountText,
          onSliderChanged: controller.pickAmount,
        ),
        if ((state.countedPortion, state.portionCount) case (
          final portion?,
          final count?,
        ))
          EatCountRow(
            label: state.markLabel(l10n, portion),
            count: count,
            decreaseTooltip: l10n.eatPageRemovePortion,
            increaseTooltip: l10n.eatPageAddPortion,
            onDecrease: (state.enteredInventoryAmount ?? 0) > 0
                ? () => controller.stepPortions(up: false)
                : null,
            onIncrease: () => controller.stepPortions(up: true),
            decreaseKey: portionDecreaseKey,
            increaseKey: portionIncreaseKey,
            valueKey: portionCountKey,
          )
        else if (state.packageCount case final packages?)
          EatCountRow(
            label: l10n.eatPagePackages,
            count: packages,
            decreaseTooltip: l10n.eatPageRemovePackage,
            increaseTooltip: l10n.eatPageAddPackage,
            onDecrease: (state.enteredInventoryAmount ?? 0) > 0
                ? () => controller.stepPackages(up: false)
                : null,
            onIncrease: () => controller.stepPackages(up: true),
            decreaseKey: packageDecreaseKey,
            increaseKey: packageIncreaseKey,
            valueKey: packageCountKey,
          ),
        if (state.usesPortionMode) ...[
          EatInlineAmountField(
            fieldKey: InventoryItemEatSheetBody.pieceWeightKey,
            label: l10n.eatPagePieceWeight(state.defaultPortionLabel(l10n)),
            unitLabel: consumedUnitSymbol(l10n, state.portionUnit),
            controller: pieceWeight.controller,
            focusNode: pieceWeight.focusNode,
            errorText: state.portionAmountError(l10n),
            onChanged: controller.setPortionAmountText,
            unitKey: InventoryItemEatSheetBody.pieceWeightUnitKey,
            onUnitPressed: units.length < 2
                ? null
                : controller.switchPortionUnit,
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final size in state.pieceSizes)
                EatChip(
                  label: state.pieceSizeLabel(l10n, size),
                  isSelected: size == selectedSize,
                  onPressed: () => controller.pickPieceSize(size),
                ),
            ],
          ),
          if (state.pieceWeightLabel(l10n) case final weight?
              when selectedSize?.label == null)
            EatRememberPortion(
              amountLabel: weight,
              linkLabel: l10n.eatPageRememberPieceSize,
              nameHint: l10n.eatPagePieceSizeNameHint,
              onSave: controller.rememberPortion,
            ),
        ] else
          EatRememberPortion(
            amountLabel: state.enteredAmountLabel(l10n),
            onSave: controller.rememberPortion,
          ),
        if (calculator.supportsInedibleAmountAdjustment)
          EatInedibleLine(
            controller: inedibleAmount.controller,
            focusNode: inedibleAmount.focusNode,
            errorText: state.inedibleError(l10n),
            unitLabel: state.amountUnit(l10n),
            summaryText: state.inedibleSummary(l10n),
            isExpanded: state.isInedibleExpanded,
            onChanged: controller.setInedibleAmountText,
            onToggleExpanded: onToggleInedible,
          ),
      ],
    );
  }
}
