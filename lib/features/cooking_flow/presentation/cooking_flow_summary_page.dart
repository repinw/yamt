import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_theme_tokens.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_amount_utils.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_summary_models.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_step_layout.dart';
import 'package:yamt/features/cooking_flow/presentation/'
    'cooking_flow_storage_container_models.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Summary step for cookflow.
class CookingFlowSummaryPage extends StatelessWidget {
  /// Creates summary step.
  const CookingFlowSummaryPage({
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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return CookingFlowStepLayout(
      title: l10n.cookflowSummaryTitle,
      subtitle: l10n.cookflowSummaryBody,
      children: <Widget>[
        DecoratedBox(
          decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
            colors,
            borderRadius: BorderRadius.circular(
              AppInventoryEditorial.cardRadius,
            ),
            blurRadius: 22,
            shadowOffset: const Offset(0, 10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: AppInsets.card,
                child: Text(
                  l10n.cookflowSummaryIngredientsTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: colors.outlineVariant.withValues(alpha: 0.45),
              ),
              Padding(
                padding: AppInsets.card,
                child: _SummaryIngredientsTable(
                  ingredients: ingredients,
                  inventoryItems: inventoryItems,
                  onAmountChanged: onAmountChanged,
                  onRemoveIngredient: onRemoveIngredient,
                  onAddIngredientSourceSelected: onAddIngredientSourceSelected,
                ),
              ),
            ],
          ),
        ),
        if (storageContainers.isNotEmpty && ingredients.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xxxxl),
          _SummaryIngredientContainerSection(
            ingredients: ingredients,
            containers: storageContainers,
            assignments: ingredientContainerAssignments,
            onChanged: onIngredientContainerChanged,
          ),
        ],
        if (adjustments.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xxxxl),
          Row(
            children: <Widget>[
              const Icon(
                Icons.warning_amber_rounded,
                color: AppSeedColors.orange,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.cookflowSummaryAdjustmentsTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
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
  const _SummaryIngredientAddMenu.row({
    required this.onSelected,
    super.key,
  }) : label = null,
       style = _SummaryIngredientAddMenuStyle.row;

  const _SummaryIngredientAddMenu.button({
    required this.label,
    required this.onSelected,
    super.key,
  }) : style = _SummaryIngredientAddMenuStyle.button;

  final String? label;
  final _SummaryIngredientAddMenuStyle style;
  final ValueChanged<CookingFlowSummaryIngredientAddSource> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final buttonLabel = label;

    return PopupMenuButton<CookingFlowSummaryIngredientAddSource>(
      tooltip: l10n.cookflowInventorySelectionAddIngredient,
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
  const _SummaryIngredientAddMenuRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add_rounded, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Icon(Icons.expand_more_rounded, color: colors.primary),
        ],
      ),
    );
  }
}

class _SummaryIngredientAddMenuButton extends StatelessWidget {
  const _SummaryIngredientAddMenuButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppInventoryEditorialSurfaces.soulGradient(colors),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: <BoxShadow>[
          AppInventoryEditorialSurfaces.ambientBoxShadow(
            colors,
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add_rounded, color: colors.onPrimary),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.expand_more_rounded, color: colors.onPrimary),
          ],
        ),
      ),
    );
  }
}

class _SummaryInventoryIngredientPicker extends StatelessWidget {
  const _SummaryInventoryIngredientPicker({required this.inventoryItems});

  final List<InventoryItem> inventoryItems;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final sortedItems = List<InventoryItem>.from(inventoryItems)
      ..sort(
        (left, right) => left.name.toLowerCase().compareTo(
          right.name.toLowerCase(),
        ),
      );

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
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
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: sortedItems.length,
                              itemBuilder: (context, index) {
                                final item = sortedItems[index];
                                return ListTile(
                                  key: Key(
                                    'cookflow_summary_inventory_item_'
                                    '${item.id}',
                                  ),
                                  contentPadding: EdgeInsets.zero,
                                  leading: PreparedMealCover(
                                    label: item.name,
                                    imageBytes: null,
                                    imageUrl: item.imageUrl,
                                    size: 40,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  title: Text(item.name),
                                  subtitle: Text(
                                    _summaryInventoryPickerAmountLabel(item),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop(item);
                                  },
                                );
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

String _summaryInventoryPickerAmountLabel(InventoryItem item) {
  if (item.usesAmountProgress && item.amountUnit != null) {
    return '${item.currentAmount} ${item.amountUnit!.code}';
  }
  return '${item.quantity}x';
}

class _SummaryIngredientsTable extends StatelessWidget {
  const _SummaryIngredientsTable({
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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: DecoratedBox(
        decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
          colors,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          color: Color.alphaBlend(
            colors.surfaceContainerLowest.withValues(alpha: 0.96),
            colors.surface,
          ),
          blurRadius: 16,
          shadowOffset: const Offset(0, 8),
        ),
        child: Column(
          children: <Widget>[
            if (ingredients.isEmpty)
              _SummaryIngredientsEmptyRow(
                message: l10n.cookflowEmptyIngredients,
              )
            else
              for (var index = 0; index < ingredients.length; index++) ...[
                if (index > 0) _SummaryIngredientDivider(colors: colors),
                _SummaryIngredientRow(
                  key: ValueKey(ingredients[index].key),
                  ingredient: ingredients[index],
                  inventoryItems: inventoryItems,
                  onChanged: (value) => onAmountChanged(index, value),
                  onDeletePressed: () => onRemoveIngredient(index),
                ),
              ],
            _SummaryIngredientDivider(colors: colors),
            _SummaryIngredientAddMenu.row(
              key: const Key('cookflow_summary_add_ingredient_button'),
              onSelected: onAddIngredientSourceSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryIngredientsEmptyRow extends StatelessWidget {
  const _SummaryIngredientsEmptyRow({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SummaryIngredientDivider extends StatelessWidget {
  const _SummaryIngredientDivider({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppInventoryEditorialSurfaces.ghostBorder(
        colors,
      ).withValues(alpha: 0.9),
    );
  }
}

class _SummaryIngredientContainerSection extends StatelessWidget {
  const _SummaryIngredientContainerSection({
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
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final assignableIngredients = ingredients
        .where((ingredient) => ingredient.inventoryItemIds.isNotEmpty)
        .toList(growable: false);

    return DecoratedBox(
      decoration: AppInventoryEditorialSurfaces.liftedCardDecoration(
        colors,
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
        blurRadius: 22,
        shadowOffset: const Offset(0, 10),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.cookflowIngredientContainerTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (assignableIngredients.isEmpty)
              Text(
                l10n.cookflowIngredientContainerEmpty,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
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
  const _SummaryIngredientContainerRow({
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
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text('${ingredient.amount} ${ingredient.unitCode}'),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        SizedBox(
          width: 180,
          child: AppDropdownButtonFormField<String>(
            initialValue: resolvedValue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.cookflowContainerLabel,
            ),
            items: <DropdownMenuItem<String>>[
              for (var index = 0; index < containers.length; index++)
                DropdownMenuItem<String>(
                  value: containers[index].id,
                  child: Text(
                    _summaryContainerLabel(
                      l10n,
                      containers[index],
                      index,
                    ),
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
  const _SummaryIngredientRow({
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
    final colors = Theme.of(context).colorScheme;
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
            size: 36,
            borderRadius: BorderRadius.circular(999),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    SizedBox(
                      width: 64,
                      child: TextFormField(
                        initialValue: ingredient.amount,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.end,
                        onChanged: onChanged,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          filled: true,
                          fillColor: colors.surfaceContainerLowest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            borderSide: BorderSide(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        ),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      ingredient.unitCode,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      onPressed: onDeletePressed,
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: colors.onSurfaceVariant,
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
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.primary,
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
  final selectedItems = inventoryItems
      .where((item) => selectedIds.contains(item.id))
      .toList(growable: false);
  if (selectedItems.isEmpty ||
      !_hasSummaryCompatibleSelection(
        selectedItems: selectedItems,
        requirement: requirement,
      )) {
    return null;
  }
  final availableAmount = _availableSummaryInventoryAmount(
    selectedItems: selectedItems,
    requirement: requirement,
  );
  final usedAmount = availableAmount < requirement.amount
      ? availableAmount
      : requirement.amount;
  final remainingAmount = availableAmount - usedAmount;
  return l10n.cookflowInventoryUsagePreview(
    _formatSummaryInventoryAmount(
      amount: usedAmount,
      unitCode: requirement.unitCode,
    ),
    _formatSummaryInventoryAmount(
      amount: remainingAmount,
      unitCode: requirement.unitCode,
    ),
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

_SummaryInventoryRequirement? _summaryInventoryRequirement(
  CookingFlowSummaryIngredientDraft ingredient,
) {
  final amount = parseCookingFlowQuantity(ingredient.amount)?.round();
  if (amount == null || amount < 1) {
    return null;
  }
  final unitCode = ingredient.unitCode.trim().toLowerCase();
  return _SummaryInventoryRequirement(
    amount: amount,
    unitCode: unitCode.isEmpty ? _summaryPieceUnitCode : unitCode,
  );
}

int _availableSummaryInventoryAmount({
  required List<InventoryItem> selectedItems,
  required _SummaryInventoryRequirement requirement,
}) {
  var total = 0;
  for (final item in selectedItems) {
    if (requirement.unitCode == _summaryPieceUnitCode) {
      if (item.usesAmountProgress && item.amountUnit?.code == 'pc') {
        total += item.currentAmount;
        continue;
      }
      total += item.quantity;
      continue;
    }
    if (!item.usesAmountProgress ||
        item.amountUnit?.code != requirement.unitCode) {
      continue;
    }
    total += item.currentAmount;
  }
  return total;
}

bool _hasSummaryCompatibleSelection({
  required List<InventoryItem> selectedItems,
  required _SummaryInventoryRequirement requirement,
}) {
  for (final item in selectedItems) {
    if (requirement.unitCode == _summaryPieceUnitCode) {
      return true;
    }
    if (item.usesAmountProgress &&
        item.amountUnit?.code == requirement.unitCode) {
      return true;
    }
  }
  return false;
}

String _formatSummaryInventoryAmount({
  required int amount,
  required String unitCode,
}) {
  if (unitCode == _summaryPieceUnitCode) {
    return amount.toString();
  }
  return '$amount$unitCode';
}

class _SummaryInventoryRequirement {
  const _SummaryInventoryRequirement({
    required this.amount,
    required this.unitCode,
  });

  final int amount;
  final String unitCode;
}

const String _summaryPieceUnitCode = 'pc';

class _UnresolvedAdjustmentCard extends StatelessWidget {
  const _UnresolvedAdjustmentCard({
    required this.adjustment,
    required this.onSourceSelected,
  });

  final String adjustment;
  final ValueChanged<CookingFlowSummaryIngredientAddSource> onSourceSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFFFFC38E)),
      ),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '"$adjustment"',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
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
