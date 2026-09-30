import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/constants/app_sizes.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/graphit_text_styles.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_conflict_resolver.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_inventory_requirement.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_parser_locale.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/presentation/models/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/'
    'cooking_flow_step_layout.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Summary step for cookflow.
class CookingFlowSummaryPage extends StatelessWidget {
  /// Creates summary step.
  const new({
    required this.ingredients,
    required this.inventoryItems,
    required this.adjustments,
    required this.onAmountChanged,
    required this.onRemoveIngredient,
    required this.onAddIngredientSourceSelected,
    required this.onAdjustmentSourceSelected,
    required this.storageContainers,
    required this.ingredientContainerAssignments,
    required this.onIngredientContainerChanged,
    super.key,
  });

  /// Editable base ingredients.
  final List<CookingFlowSummaryIngredientDraft> ingredients;

  /// Current inventory items for usage preview.
  final List<InventoryItem> inventoryItems;

  /// Unresolved on-the-fly notes.
  final List<String> adjustments;

  /// Selected storage containers.
  final List<CookingFlowStorageContainerView> storageContainers;

  /// Ingredient row key to container id.
  final Map<String, String> ingredientContainerAssignments;

  /// Amount change callback.
  final void Function(int index, String value) onAmountChanged;

  /// Delete callback.
  final void Function(int index) onRemoveIngredient;

  /// Adds an ingredient through the selected source.
  final ValueChanged<CookingFlowSummaryIngredientAddSource>
  onAddIngredientSourceSelected;

  /// Resolves an adjustment through the selected source.
  final void Function(int index, CookingFlowSummaryIngredientAddSource source)
  onAdjustmentSourceSelected;

  /// Changes ingredient-to-container assignment.
  final void Function(String rowKey, String containerId)
  onIngredientContainerChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final schemeColors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final sectionTitleStyle = textTheme.titleMedium?.copyWith(
      color: colors.ink,
      fontWeight: FontWeight.w800,
    );

    return CookingFlowStepLayout(
      title: l10n.cookflowSummaryTitle,
      subtitle: l10n.cookflowSummaryBody,
      children: <Widget>[
        Text(l10n.cookflowSummaryIngredientsTitle, style: sectionTitleStyle),
        const SizedBox(height: AppSpacing.lg),
        _SummaryIngredientsTable(
          ingredients: ingredients,
          inventoryItems: inventoryItems,
          onAmountChanged: onAmountChanged,
          onRemoveIngredient: onRemoveIngredient,
          onAddIngredientSourceSelected: onAddIngredientSourceSelected,
        ),
        if (storageContainers.isNotEmpty && ingredients.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xxxl),
          _SummaryIngredientContainerSection(
            ingredients: ingredients,
            containers: storageContainers,
            assignments: ingredientContainerAssignments,
            onChanged: onIngredientContainerChanged,
          ),
        ],
        if (adjustments.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xxxl),
          Row(
            children: <Widget>[
              Icon(Icons.warning_amber_rounded, color: schemeColors.error),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.cookflowSummaryAdjustmentsTitle,
                style: sectionTitleStyle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var index = 0; index < adjustments.length; index++) ...<Widget>[
            _UnresolvedAdjustmentCard(
              adjustment: adjustments[index],
              onSourceSelected: (source) {
                onAdjustmentSourceSelected(index, source);
              },
            ),
            if (index != adjustments.length - 1)
              const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ],
    );
  }
}

/// Source for adding a cookflow summary ingredient.
enum CookingFlowSummaryIngredientAddSource {
  /// Existing inventory item.
  inventory,

  /// New item from barcode scan.
  barcode,

  /// New item from manual search.
  manualSearch,

  /// New item from AI suggestion.
  ai,
}

/// Shows inventory picker for cookflow summary ingredient selection.
Future<InventoryItem?> showCookingFlowSummaryInventoryIngredientPicker({
  required BuildContext context,
  required List<InventoryItem> inventoryItems,
}) {
  return showModalBottomSheet<InventoryItem>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _SummaryInventoryIngredientPicker(inventoryItems: inventoryItems);
    },
  );
}

class _SummaryIngredientAddMenu extends StatelessWidget {
  const new row({required this.onSelected, super.key})
    : label = null,
      style = _SummaryIngredientAddMenuStyle.row;

  const new button({required this.label, required this.onSelected, super.key})
    : style = _SummaryIngredientAddMenuStyle.button;

  final String? label;
  final _SummaryIngredientAddMenuStyle style;
  final ValueChanged<CookingFlowSummaryIngredientAddSource> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buttonLabel = label;

    return PopupMenuButton<CookingFlowSummaryIngredientAddSource>(
      tooltip: l10n.cookflowInventorySelectionAddIngredient,
      useRootNavigator: true,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      child: style == _SummaryIngredientAddMenuStyle.row
          ? _SummaryIngredientAddMenuRow(
              label: l10n.cookflowInventorySelectionAddIngredient,
            )
          : _SummaryIngredientAddMenuButton(label: buttonLabel ?? ''),
      itemBuilder: (context) {
        return <PopupMenuEntry<CookingFlowSummaryIngredientAddSource>>[
          _menuItem(
            value: CookingFlowSummaryIngredientAddSource.inventory,
            icon: Icons.kitchen_outlined,
            label: l10n.diaryQuickEatSourceInventory,
          ),
          _menuItem(
            value: CookingFlowSummaryIngredientAddSource.barcode,
            icon: Icons.qr_code_scanner_rounded,
            label: l10n.diaryQuickEatSourceBarcode,
          ),
          _menuItem(
            value: CookingFlowSummaryIngredientAddSource.manualSearch,
            icon: Icons.search_rounded,
            label: l10n.diaryQuickEatSourceManualSearch,
          ),
          _menuItem(
            value: CookingFlowSummaryIngredientAddSource.ai,
            icon: Icons.auto_awesome_rounded,
            label: l10n.diaryQuickEatSourceAi,
          ),
        ];
      },
    );
  }

  PopupMenuItem<CookingFlowSummaryIngredientAddSource> _menuItem({
    required CookingFlowSummaryIngredientAddSource value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<CookingFlowSummaryIngredientAddSource>(
      key: Key('cookflow_summary_add_source_${value.name}'),
      value: value,
      child: Row(
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: AppSpacing.md),
          Text(label),
        ],
      ),
    );
  }
}

enum _SummaryIngredientAddMenuStyle { button, row }

class _SummaryIngredientAddMenuRow extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: AppGraphit.badge,
            height: AppGraphit.badge,
            color: colors.tile,
            child: Icon(
              Icons.add_rounded,
              color: colors.ink,
              size: AppGraphit.toolIcon,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colors.ink, fontWeight: FontWeight.w700),
            ),
          ),
          Icon(Icons.expand_more_rounded, color: colors.muted),
        ],
      ),
    );
  }
}

class _SummaryIngredientAddMenuButton extends StatelessWidget {
  const new({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tile,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppGraphit.buttonHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                Icons.expand_more_rounded,
                color: colors.ink,
                size: AppGraphit.toolIcon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet that lists the Vorrat, sorted by name, to pick one item.
class _SummaryInventoryIngredientPicker extends StatelessWidget {
  const new({required this.inventoryItems});

  final List<InventoryItem> inventoryItems;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final sortedItems = List<InventoryItem>.from(inventoryItems)
      ..sort(
        (left, right) =>
            left.name.toLowerCase().compareTo(right.name.toLowerCase()),
      );

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: AppInsets.pageLarge,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.cookflowInventorySelectionTitle,
                          style: context.graphitDisplayStyle(
                            textTheme.titleLarge,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        color: colors.ink,
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                      ),
                      child: sortedItems.isEmpty
                          ? Center(
                              child: Padding(
                                padding: AppInsets.card,
                                child: Text(
                                  l10n.cookflowInventorySelectionEmpty,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colors.muted,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: sortedItems.length,
                              separatorBuilder: (_, _) =>
                                  const _SummaryIngredientDivider(),
                              itemBuilder: (context, index) {
                                final item = sortedItems[index];
                                return _SummaryInventoryPickerRow(item: item);
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryInventoryPickerRow extends StatelessWidget {
  const new({required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        key: Key('cookflow_summary_inventory_item_${item.id}'),
        contentPadding: EdgeInsets.zero,
        leading: PreparedMealCover(
          label: item.name,
          imageBytes: null,
          imageUrl: item.imageUrl,
          size: AppGraphit.rowTile,
          borderRadius: BorderRadius.zero,
        ),
        title: Text(
          item.name,
          style: textTheme.titleSmall?.copyWith(
            color: colors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          cookingFlowInventoryAmountLabel(item),
          style: textTheme.bodySmall?.copyWith(color: colors.muted),
        ),
        onTap: () => Navigator.of(context).pop(item),
      ),
    );
  }
}

class _SummaryIngredientsTable extends StatelessWidget {
  const new({
    required this.ingredients,
    required this.inventoryItems,
    required this.onAmountChanged,
    required this.onRemoveIngredient,
    required this.onAddIngredientSourceSelected,
  });

  final List<CookingFlowSummaryIngredientDraft> ingredients;
  final List<InventoryItem> inventoryItems;
  final void Function(int index, String value) onAmountChanged;
  final void Function(int index) onRemoveIngredient;
  final ValueChanged<CookingFlowSummaryIngredientAddSource>
  onAddIngredientSourceSelected;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.rule),
      ),
      child: Column(
        children: <Widget>[
          if (ingredients.isEmpty)
            _SummaryIngredientsEmptyRow(message: l10n.cookflowEmptyIngredients)
          else
            for (var index = 0; index < ingredients.length; index++) ...[
              if (index > 0) const _SummaryIngredientDivider(),
              _SummaryIngredientRow(
                key: ValueKey(ingredients[index].key),
                ingredient: ingredients[index],
                inventoryItems: inventoryItems,
                onChanged: (value) => onAmountChanged(index, value),
                onDeletePressed: () => onRemoveIngredient(index),
              ),
            ],
          const _SummaryIngredientDivider(),
          _SummaryIngredientAddMenu.row(
            key: const Key('cookflow_summary_add_ingredient_button'),
            onSelected: onAddIngredientSourceSelected,
          ),
        ],
      ),
    );
  }
}

class _SummaryIngredientsEmptyRow extends StatelessWidget {
  const new({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.muted),
        ),
      ),
    );
  }
}

class _SummaryIngredientDivider extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: AppSizes.dividerThickness,
      thickness: AppSizes.dividerThickness,
      color: FoodLabelColors.of(context).rule,
    );
  }
}

class _SummaryIngredientContainerSection extends StatelessWidget {
  const new({
    required this.ingredients,
    required this.containers,
    required this.assignments,
    required this.onChanged,
  });

  final List<CookingFlowSummaryIngredientDraft> ingredients;
  final List<CookingFlowStorageContainerView> containers;
  final Map<String, String> assignments;
  final void Function(String rowKey, String containerId) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final assignableIngredients = ingredients
        .where((ingredient) => ingredient.inventoryItemIds.isNotEmpty)
        .toList(growable: false);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.rule),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.cookflowIngredientContainerTitle,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: colors.ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (assignableIngredients.isEmpty)
              Text(
                l10n.cookflowIngredientContainerEmpty,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.muted),
              )
            else
              for (final ingredient in assignableIngredients) ...<Widget>[
                _SummaryIngredientContainerRow(
                  ingredient: ingredient,
                  containers: containers,
                  selectedContainerId: assignments[ingredient.key],
                  onChanged: onChanged,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
          ],
        ),
      ),
    );
  }
}

class _SummaryIngredientContainerRow extends StatelessWidget {
  const new({
    required this.ingredient,
    required this.containers,
    required this.selectedContainerId,
    required this.onChanged,
  });

  final CookingFlowSummaryIngredientDraft ingredient;
  final List<CookingFlowStorageContainerView> containers;
  final String? selectedContainerId;
  final void Function(String rowKey, String containerId) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validContainerIds = containers.map((container) => container.id);
    final resolvedValue = validContainerIds.contains(selectedContainerId)
        ? selectedContainerId
        : containers.isEmpty
        ? null
        : containers.first.id;

    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                ingredient.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: FoodLabelColors.of(context).ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${ingredient.amount} ${ingredient.unitCode}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: FoodLabelColors.of(context).muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        SizedBox(
          width: 180,
          child: AppDropdownButtonFormField<String>(
            initialValue: resolvedValue,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.cookflowContainerLabel),
            items: <DropdownMenuItem<String>>[
              for (var index = 0; index < containers.length; index++)
                DropdownMenuItem<String>(
                  value: containers[index].id,
                  child: Text(
                    _summaryContainerLabel(l10n, containers[index], index),
                  ),
                ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              onChanged(ingredient.key, value);
            },
          ),
        ),
      ],
    );
  }
}

String _summaryContainerLabel(
  AppLocalizations l10n,
  CookingFlowStorageContainerView container,
  int index,
) {
  final label = container.labelController.text.trim();
  if (label.isNotEmpty) {
    return label;
  }
  return l10n.cookflowContainerNameHint(index + 1);
}

class _SummaryIngredientRow extends StatelessWidget {
  const new({
    required super.key,
    required this.ingredient,
    required this.inventoryItems,
    required this.onChanged,
    required this.onDeletePressed,
  });

  final CookingFlowSummaryIngredientDraft ingredient;
  final List<InventoryItem> inventoryItems;
  final ValueChanged<String> onChanged;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    );
    final l10n = AppLocalizations.of(context)!;
    final usagePreview = _summaryUsagePreviewLabel(
      l10n: l10n,
      ingredient: ingredient,
      inventoryItems: inventoryItems,
    );
    final previewItem = _summaryPrimaryInventoryItem(
      ingredient: ingredient,
      inventoryItems: inventoryItems,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          PreparedMealCover(
            label: previewItem?.name ?? ingredient.name,
            imageBytes: null,
            imageUrl: previewItem?.imageUrl,
            size: AppGraphit.badge,
            borderRadius: BorderRadius.zero,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        ingredient.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: AppGraphit.numberField,
                      child: TextFormField(
                        initialValue: ingredient.amount,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        onChanged: onChanged,
                        cursorColor: colors.ink,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          filled: true,
                          fillColor: colors.tile,
                          border: fieldBorder,
                          enabledBorder: fieldBorder,
                          focusedBorder: fieldBorder,
                        ),
                        style: context.graphitDisplayStyle(
                          textTheme.titleMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      ingredient.unitCode,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      onPressed: onDeletePressed,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colors.muted,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ],
                ),
                if (usagePreview != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    usagePreview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String? _summaryUsagePreviewLabel({
  required AppLocalizations l10n,
  required CookingFlowSummaryIngredientDraft ingredient,
  required List<InventoryItem> inventoryItems,
}) {
  final requirement = _summaryInventoryRequirement(ingredient);
  if (requirement == null || ingredient.inventoryItemIds.isEmpty) {
    return null;
  }
  final selectedIds = ingredient.inventoryItemIds.toSet();
  final usagePreview = cookingFlowInventoryUsagePreviewForItems(
    requirement: requirement,
    selectedItems: inventoryItems
        .where((item) => selectedIds.contains(item.id))
        .toList(growable: false),
  );
  if (usagePreview == null) {
    return null;
  }
  return l10n.cookflowInventoryUsagePreview(
    usagePreview.usedAmountLabel,
    usagePreview.remainingAmountLabel,
  );
}

InventoryItem? _summaryPrimaryInventoryItem({
  required CookingFlowSummaryIngredientDraft ingredient,
  required List<InventoryItem> inventoryItems,
}) {
  if (ingredient.inventoryItemIds.isEmpty) {
    return null;
  }
  final primaryId = ingredient.inventoryItemIds.first;
  for (final item in inventoryItems) {
    if (item.id == primaryId) {
      return item;
    }
  }
  return null;
}

CookingFlowInventoryRequirement? _summaryInventoryRequirement(
  CookingFlowSummaryIngredientDraft ingredient,
) {
  final amount = parseCookingFlowQuantity(ingredient.amount);
  if (amount == null || amount <= 0) {
    return null;
  }
  final unitCode = ingredient.unitCode.trim().toLowerCase();
  return CookingFlowInventoryRequirement(
    amount: amount,
    unitCode: unitCode.isEmpty ? cookingFlowPieceUnitCode : unitCode,
  );
}

class _UnresolvedAdjustmentCard extends StatelessWidget {
  const new({required this.adjustment, required this.onSourceSelected});

  final String adjustment;
  final ValueChanged<CookingFlowSummaryIngredientAddSource> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final schemeColors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: schemeColors.error),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '"$adjustment"',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: colors.ink, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: _SummaryIngredientAddMenu.button(
                key: const Key('cookflow_summary_adjustment_add_button'),
                label: l10n.cookflowSummaryMatchInventoryButton,
                onSelected: onSourceSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
