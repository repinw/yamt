import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/presentation/models/cooking_flow_localizations.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_inventory_conflict_panel/cooking_flow_conflict_resolution_button.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_inventory_conflict_panel/cooking_flow_inventory_unit_conflict_panel.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Shortage or unit conflict of one ingredient row with its ways out.
class CookingFlowInventoryConflictPanel extends StatelessWidget {
  /// Creates the panel.
  const new({
    required this.conflict,
    required this.selectedResolution,
    required this.onBuyRemainingPressed,
    required this.onAdjustTemplatePressed,
    required this.onConvertUnitPressed,
    required this.onWeighLaterPressed,
    super.key,
  });

  /// The conflict to show.
  final CookingFlowInventoryCheckConflict conflict;

  /// Chosen way out, if any.
  final CookingFlowInventoryConflictResolution? selectedResolution;

  /// Buys the missing amount.
  final VoidCallback onBuyRemainingPressed;

  /// Lowers the recipe amount to the stock.
  final VoidCallback onAdjustTemplatePressed;

  /// Converts the unit with the grams per unit.
  final ValueChanged<double> onConvertUnitPressed;

  /// Weighs the ingredient later.
  final VoidCallback onWeighLaterPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (conflict.kind == CookingFlowInventoryConflictKind.unitConversion) {
      return CookingFlowInventoryUnitConflictPanel(
        conflict: conflict,
        selectedResolution: selectedResolution,
        onConvertUnitPressed: onConvertUnitPressed,
        onWeighLaterPressed: onWeighLaterPressed,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: colors.error,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                cookingFlowInventoryConflictMessage(
                  l10n: l10n,
                  availableLabel: conflict.availableAmountLabel,
                  missingLabel: conflict.missingAmountLabel,
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
            Expanded(
              child: CookingFlowConflictResolutionButton(
                label: l10n.cookflowBuyRemainingButton,
                isActive:
                    selectedResolution ==
                    CookingFlowInventoryConflictResolution.buyRemaining,
                onPressed: onBuyRemainingPressed,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: CookingFlowConflictResolutionButton(
                label: l10n.cookflowAdjustTemplateButton,
                isActive:
                    selectedResolution ==
                    CookingFlowInventoryConflictResolution.adjustTemplate,
                onPressed: onAdjustTemplatePressed,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Localized shortage message with the available and the missing amount.
String cookingFlowInventoryConflictMessage({
  required AppLocalizations l10n,
  required String availableLabel,
  required String missingLabel,
}) {
  return l10n.cookflowInventoryConflictText(
    availableAmount: availableLabel,
    missingAmount: missingLabel,
  );
}
