import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_inventory_assignment_sheet/'
    'cooking_flow_inventory_assignment_preview.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Name, amount and usage preview of one ingredient row of the intro step.
class CookingFlowInventoryCheckRowText extends StatelessWidget {
  /// Creates the row text.
  const new({
    required this.row,
    required this.amountLabel,
    required this.selectedAction,
    required this.selectedSelections,
    required this.inventoryItems,
    required this.localeCode,
    required this.onEditPressed,
    super.key,
  });

  /// Ingredient of the row.
  final CookingFlowInventoryCheckRowData row;

  /// Amount shown under the name.
  final String amountLabel;

  /// Choice made for the row, if any.
  final CookingFlowInventoryRowAction? selectedAction;

  /// Inventory items assigned to the row.
  final List<CookingFlowInventoryAssignmentSelection> selectedSelections;

  /// All inventory items, to resolve the selections.
  final List<InventoryItem> inventoryItems;

  /// Locale for amount formatting.
  final String localeCode;

  /// Opens the ingredient editor.
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
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
          style: textTheme.titleMedium?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                amountLabel.isEmpty ? l10n.cookflowUnknownAmount : amountLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(color: colors.muted),
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            IconButton(
              tooltip: l10n.cookflowEditIngredientTooltip,
              onPressed: onEditPressed,
              icon: const Icon(Icons.edit_outlined),
              color: colors.muted,
              iconSize: 14,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 24, height: 24),
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
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.cookflowInventoryUsagePreview(
              usagePreview.usedAmountLabel,
              usagePreview.remainingAmountLabel,
            ),
            style: textTheme.labelMedium?.copyWith(
              color: colors.ink,
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
                .map((item) {
                  final amountLabel = cookingFlowInventoryAmountLabel(item);
                  return _AdditionalAssignedInventoryPill(
                    imageLabel: item.name,
                    imageUrl: item.imageUrl,
                    label: '+ ${item.name} $amountLabel',
                  );
                })
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

/// Name of the first assigned item, or an empty string.
String cookingFlowSelectedInventoryTitle(List<InventoryItem> selectedItems) {
  if (selectedItems.isEmpty) {
    return '';
  }
  return selectedItems.first.name;
}

class _AdditionalAssignedInventoryPill extends StatelessWidget {
  const new({
    required this.imageLabel,
    required this.imageUrl,
    required this.label,
  });

  final String imageLabel;
  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: BorderRadius.circular(AppRadius.pill),
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
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: colors.ink, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
