// Internal split widgets/helpers are public only for sibling imports.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_assignment.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_localizations.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

const Color cookingFlowConflictBorderColor = Color(0xFFFFA24A);
const Color _conflictTextColor = Color(0xFFB95B00);
const Color _conflictBackgroundColor = Color(0xFFFFE7D6);

class CookingFlowInventoryConflictPanel extends StatelessWidget {
  const CookingFlowInventoryConflictPanel({
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
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: cookingFlowConflictBorderColor,
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
                  color: _conflictTextColor,
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
                backgroundColor: colors.primaryContainer.withValues(alpha: 0.8),
                foregroundColor: colors.primary,
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
                backgroundColor: _conflictBackgroundColor,
                foregroundColor: _conflictTextColor,
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
  const CookingFlowInventoryReturnSuggestionPanel({
    required this.item,
    required this.onPressed,
  });

  final InventoryItem item;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final amountLabel = cookingFlowInventoryAmountLabel(item);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.inventory_2_rounded,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Row(
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
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${item.name} · $amountLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.tonal(
            onPressed: onPressed,
            child: Text(l10n.cookflowInventoryReturnSuggestionButton),
          ),
        ],
      ),
    );
  }
}

class _ConflictResolutionButton extends StatelessWidget {
  const _ConflictResolutionButton({
    required this.label,
    required this.isActive,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final bool isActive;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        side: BorderSide(
          color: isActive
              ? foregroundColor.withValues(alpha: 0.7)
              : Colors.transparent,
          width: 1.2,
        ),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CookingFlowInventoryUnitConflictPanel extends StatefulWidget {
  const CookingFlowInventoryUnitConflictPanel({
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
      CookingFlowInventoryUnitConflictPanelState();
}

class CookingFlowInventoryUnitConflictPanelState
    extends State<CookingFlowInventoryUnitConflictPanel> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '100');
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
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.balance_rounded,
                size: 18,
                color: cookingFlowConflictBorderColor,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.cookflowInventoryUnitConflictMessage(
                  widget.conflict.requiredUnitCode,
                  selectedUnit,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _conflictTextColor,
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
              l10n.cookflowInventoryUnitConversionPrefix,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
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
            FilledButton.tonal(
              onPressed: _convert,
              child: Text(l10n.cookflowInventoryUnitConvertAction),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: widget.onWeighLaterPressed,
            icon: const Icon(Icons.schedule_rounded),
            label: Text(l10n.cookflowInventoryUnitWeighLaterAction),
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
