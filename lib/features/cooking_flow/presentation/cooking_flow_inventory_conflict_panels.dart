// Internal split widgets/helpers are public only for sibling imports.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_requirement.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_action_button.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_assignment.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_localizations.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CookingFlowInventoryConflictPanel extends StatelessWidget {
  const new({
    required this.conflict,
    required this.selectedResolution,
    required this.onBuyRemainingPressed,
    required this.onAdjustTemplatePressed,
    required this.onConvertUnitPressed,
    required this.onWeighLaterPressed,
  });

  final CookingFlowInventoryCheckConflict conflict;
  final CookingFlowInventoryConflictResolution? selectedResolution;
  final VoidCallback onBuyRemainingPressed;
  final VoidCallback onAdjustTemplatePressed;
  final ValueChanged<double> onConvertUnitPressed;
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
              child: _ConflictResolutionButton(
                label: l10n.cookflowBuyRemainingButton,
                isActive:
                    selectedResolution ==
                    CookingFlowInventoryConflictResolution.buyRemaining,
                onPressed: onBuyRemainingPressed,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ConflictResolutionButton(
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

class CookingFlowInventoryReturnSuggestionPanel extends StatelessWidget {
  const new({required this.item, required this.onPressed});

  final InventoryItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final amountLabel = cookingFlowInventoryAmountLabel(item);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              CookingFlowInventoryAssignmentPreview(
                label: item.name,
                imageUrl: item.imageUrl,
                size: 28,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.cookflowInventoryReturnSuggestion,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.name} · $amountLabel',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: CookingFlowSecondaryActionButton(
              label: l10n.cookflowInventoryReturnSuggestionButton,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}

/// One way out of a conflict, as a chip. The chosen one is filled with ink.
class _ConflictResolutionButton extends StatelessWidget {
  const new({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final foreground = isActive ? colors.paper : colors.ink;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: isActive ? colors.ink : colors.tile,
        minimumSize: const Size(AppGraphit.chipHeight, AppGraphit.chipHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class CookingFlowInventoryUnitConflictPanel extends StatefulWidget {
  const new({
    required this.conflict,
    required this.selectedResolution,
    required this.onConvertUnitPressed,
    required this.onWeighLaterPressed,
  });

  final CookingFlowInventoryCheckConflict conflict;
  final CookingFlowInventoryConflictResolution? selectedResolution;
  final ValueChanged<double> onConvertUnitPressed;
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
