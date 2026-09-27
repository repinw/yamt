// Internal split widgets/helpers are public only for sibling imports.
// ignore_for_file: public_member_api_docs

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_food_label_constants.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_inventory_conflict_panels.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_inventory_row_actions.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_intro_row_text.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';

/// One ingredient of the intro step: a framed picture, the name and amount,
/// the three choices as chips, and the conflict or suggestion panel under it.
/// Rows are flat and separated by a rule, like the Vorrat list.
class CookingFlowInventoryCheckRow extends StatelessWidget {
  const new({
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
    final colors = FoodLabelColors.of(context);
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

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _CookingFlowRowTile(
                  label: primarySelectedItem?.name ?? row.name,
                  imageUrl: primarySelectedItem?.imageUrl ?? row.imageUrl,
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
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            CookingFlowInventoryRowActions(
              selectedAction: selectedAction,
              onAssignPressed: onAssignPressed,
              onShoppingPressed: onShoppingPressed,
              onIgnorePressed: onIgnorePressed,
            ),
            if (conflict != null) ...<Widget>[
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

/// Square framed picture of a row. Square, because it shows something.
class _CookingFlowRowTile extends StatelessWidget {
  const new({required this.label, required this.imageUrl});

  final String label;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tile,
        border: Border.all(color: colors.ink, width: AppFoodLabel.chipOutline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppFoodLabel.chipOutline),
        child: PreparedMealCover(
          label: label,
          imageBytes: null,
          imageUrl: imageUrl,
          size: AppGraphit.rowTile - 4 * AppFoodLabel.chipOutline,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}
