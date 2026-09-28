import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_inventory_requirement.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_quiet_button.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_action_button/cooking_flow_secondary_action_button.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Unit conflict of one ingredient row: convert with grams per unit, or
/// weigh later.
class CookingFlowInventoryUnitConflictPanel extends StatefulWidget {
  /// Creates the panel.
  const new({
    required this.conflict,
    required this.selectedResolution,
    required this.onConvertUnitPressed,
    required this.onWeighLaterPressed,
    super.key,
  });

  /// The unit conflict to show.
  final CookingFlowInventoryCheckConflict conflict;

  /// Chosen way out, if any.
  final CookingFlowInventoryConflictResolution? selectedResolution;

  /// Converts the unit with the grams per unit.
  final ValueChanged<double> onConvertUnitPressed;

  /// Weighs the ingredient later.
  final VoidCallback onWeighLaterPressed;

  @override
  State<CookingFlowInventoryUnitConflictPanel> createState() =>
      _CookingFlowInventoryUnitConflictPanelState();
}

class _CookingFlowInventoryUnitConflictPanelState
    extends State<CookingFlowInventoryUnitConflictPanel> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: formatCookingFlowDecimal(_defaultConversionAmount),
    );
  }

  double get _defaultConversionAmount {
    return switch (widget.conflict.requiredUnitCode) {
      cookingFlowTablespoonUnitCode => cookingFlowDefaultGramsPerTablespoon,
      cookingFlowTeaspoonUnitCode => cookingFlowDefaultGramsPerTeaspoon,
      _ => 100,
    };
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final selectedUnit = widget.conflict.selectedUnitCode ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.balance_rounded, size: 18, color: colors.error),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.cookflowInventoryUnitConflictMessage(
                  widget.conflict.requiredUnitCode,
                  selectedUnit,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Text(
              l10n.cookflowInventoryUnitConversionPrefix(
                _requiredUnitLabel(l10n),
              ),
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: FoodLabelColors.of(context).muted),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 76,
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(selectedUnit),
            const Spacer(),
            CookingFlowSecondaryActionButton(
              label: l10n.cookflowInventoryUnitConvertAction,
              onPressed: _convert,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerRight,
          child: CookingFlowQuietButton(
            label: l10n.cookflowInventoryUnitWeighLaterAction,
            onPressed: widget.onWeighLaterPressed,
          ),
        ),
      ],
    );
  }

  void _convert() {
    final amount = parseCookingFlowQuantity(_amountController.text);
    if (amount == null || amount <= 0) {
      return;
    }
    widget.onConvertUnitPressed(amount);
  }

  String _requiredUnitLabel(AppLocalizations l10n) {
    return switch (widget.conflict.requiredUnitCode) {
      cookingFlowTablespoonUnitCode => l10n.cookflowInventoryUnitTablespoon,
      cookingFlowTeaspoonUnitCode => l10n.cookflowInventoryUnitTeaspoon,
      _ => l10n.inventoryItemEatSheetUnitPiece,
    };
  }
}
