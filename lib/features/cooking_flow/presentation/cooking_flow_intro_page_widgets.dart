// Internal split widgets/helpers are public only for sibling imports.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_intro_page_assignment.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_inventory_conflict_panels.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_inventory_row_actions.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/constants/'
    'inventory_ui_constants.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CookingFlowInventoryCheckRow extends StatelessWidget {
  const CookingFlowInventoryCheckRow({
    required this.row,
    required this.selectedAction,
    required this.selectedSelections,
    required this.inventoryItems,
    required this.localeCode,
    required this.conflict,
    required this.conflictResolution,
    required this.suggestedItem,
    required this.onAssignPressed,
    required this.onEditPressed,
    required this.onShoppingPressed,
    required this.onIgnorePressed,
    required this.onBuyRemainingPressed,
    required this.onAdjustTemplatePressed,
    required this.onConvertUnitPressed,
    required this.onWeighLaterPressed,
    required this.onApplySuggestedItem,
    super.key,
  });

  final CookingFlowInventoryCheckRowData row;
  final CookingFlowInventoryRowAction? selectedAction;
  final List<CookingFlowInventoryAssignmentSelection> selectedSelections;
  final List<InventoryItem> inventoryItems;
  final String localeCode;
  final CookingFlowInventoryCheckConflict? conflict;
  final CookingFlowInventoryConflictResolution? conflictResolution;
  final InventoryItem? suggestedItem;
  final VoidCallback onAssignPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onShoppingPressed;
  final VoidCallback onIgnorePressed;
  final VoidCallback onBuyRemainingPressed;
  final VoidCallback onAdjustTemplatePressed;
  final ValueChanged<double> onConvertUnitPressed;
  final VoidCallback onWeighLaterPressed;
  final VoidCallback? onApplySuggestedItem;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final successColors = AppInventoryEatActionColors.fromColorScheme(colors);
    final hasUnresolvedConflict =
        conflict != null && conflictResolution == null;
    final hasSuggestion = suggestedItem != null;
    final isCompleted = selectedAction != null;
    final selectedItems = cookingFlowResolveSelectedInventoryItems(
      selectedSelections: selectedSelections,
      inventoryItems: inventoryItems,
    );
    final primarySelectedItem =
        selectedAction == CookingFlowInventoryRowAction.assigned &&
            selectedItems.isNotEmpty
        ? selectedItems.first
        : null;
    final displayAmountLabel = cookingFlowInventoryRowDisplayAmountLabel(
      row: row,
      selectedAction: selectedAction,
      selectedSelections: selectedSelections,
      inventoryItems: inventoryItems,
      conflictResolution: conflictResolution,
      localeCode: localeCode,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: hasUnresolvedConflict
          ? BoxDecoration(
              color: AppEditorialSurfaces.liftedCard(colors),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: cookingFlowConflictBorderColor,
                width: 1.4,
              ),
              boxShadow: <BoxShadow>[
                AppEditorialSurfaces.ambientBoxShadow(
                  colors,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : hasSuggestion
          ? BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.4),
                width: 1.4,
              ),
              boxShadow: <BoxShadow>[
                AppEditorialSurfaces.ambientBoxShadow(
                  colors,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : isCompleted
          ? BoxDecoration(
              color: AppEditorialSurfaces.liftedCard(colors),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: successColors.borderColor,
                width: 1.4,
              ),
              boxShadow: <BoxShadow>[
                AppEditorialSurfaces.ambientBoxShadow(
                  colors,
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : AppEditorialSurfaces.liftedCardDecoration(
              colors,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              blurRadius: 14,
              shadowOffset: const Offset(0, 6),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                PreparedMealCover(
                  label: primarySelectedItem?.name ?? row.name,
                  imageBytes: null,
                  imageUrl: primarySelectedItem?.imageUrl ?? row.imageUrl,
                  size: 52,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: CookingFlowInventoryCheckRowText(
                    row: row,
                    amountLabel: displayAmountLabel,
                    selectedAction: selectedAction,
                    selectedSelections: selectedSelections,
                    inventoryItems: inventoryItems,
                    localeCode: localeCode,
                    onEditPressed: onEditPressed,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                CookingFlowInventoryRowActions(
                  selectedAction: selectedAction,
                  onAssignPressed: onAssignPressed,
                  onShoppingPressed: onShoppingPressed,
                  onIgnorePressed: onIgnorePressed,
                ),
              ],
            ),
            if (conflict != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              Divider(
                height: 1,
                color: hasUnresolvedConflict
                    ? cookingFlowConflictBorderColor.withValues(alpha: 0.28)
                    : colors.outlineVariant.withValues(alpha: 0.22),
              ),
              const SizedBox(height: AppSpacing.md),
              CookingFlowInventoryConflictPanel(
                conflict: conflict!,
                selectedResolution: conflictResolution,
                onBuyRemainingPressed: onBuyRemainingPressed,
                onAdjustTemplatePressed: onAdjustTemplatePressed,
                onConvertUnitPressed: onConvertUnitPressed,
                onWeighLaterPressed: onWeighLaterPressed,
              ),
            ],
            if (suggestedItem != null &&
                onApplySuggestedItem != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              CookingFlowInventoryReturnSuggestionPanel(
                item: suggestedItem!,
                onPressed: onApplySuggestedItem!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CookingFlowInventoryCheckRowText extends StatelessWidget {
  const CookingFlowInventoryCheckRowText({
    required this.row,
    required this.amountLabel,
    required this.selectedAction,
    required this.selectedSelections,
    required this.inventoryItems,
    required this.localeCode,
    required this.onEditPressed,
  });

  final CookingFlowInventoryCheckRowData row;
  final String amountLabel;
  final CookingFlowInventoryRowAction? selectedAction;
  final List<CookingFlowInventoryAssignmentSelection> selectedSelections;
  final List<InventoryItem> inventoryItems;
  final String localeCode;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedItems = cookingFlowResolveSelectedInventoryItems(
      selectedSelections: selectedSelections,
      inventoryItems: inventoryItems,
    );
    final showsAssignedTitle =
        selectedAction == CookingFlowInventoryRowAction.assigned &&
        selectedItems.isNotEmpty;
    final titleText = showsAssignedTitle
        ? cookingFlowSelectedInventoryTitle(selectedItems)
        : row.name;
    final additionalItems = selectedItems.length > 1
        ? selectedItems.skip(1).toList(growable: false)
        : const <InventoryItem>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          titleText,
          maxLines: 3,
          overflow: TextOverflow.visible,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                amountLabel.isEmpty ? l10n.cookflowUnknownAmount : amountLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            IconButton(
              tooltip: l10n.cookflowEditIngredientTooltip,
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit_outlined),
              iconSize: 14,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
        if (cookingFlowInventoryUsagePreview(
              amountLabel: amountLabel,
              selectedAction: selectedAction,
              selectedSelections: selectedSelections,
              inventoryItems: inventoryItems,
              localeCode: localeCode,
            )
            case final usagePreview?) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.cookflowInventoryUsagePreview(
              usagePreview.usedAmountLabel,
              usagePreview.remainingAmountLabel,
            ),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (additionalItems.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: additionalItems
                .map(
                  (item) {
                    final amountLabel = cookingFlowInventoryAmountLabel(item);
                    return _AdditionalAssignedInventoryPill(
                      imageLabel: item.name,
                      imageUrl: item.imageUrl,
                      label: '+ ${item.name} $amountLabel',
                    );
                  },
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

String cookingFlowSelectedInventoryTitle(List<InventoryItem> selectedItems) {
  if (selectedItems.isEmpty) {
    return '';
  }
  return selectedItems.first.name;
}

class _AdditionalAssignedInventoryPill extends StatelessWidget {
  const _AdditionalAssignedInventoryPill({
    required this.imageLabel,
    required this.imageUrl,
    required this.label,
  });

  final String imageLabel;
  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CookingFlowInventoryAssignmentPreview(
            label: imageLabel,
            imageUrl: imageUrl,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
