// Internal detail split files expose helpers only to sibling files.
// Local imports avoid stale package resolution across worktrees.
// ignore_for_file: always_use_package_imports, public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/'
    'recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'prepared_meal_templates_controller.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';
import 'package:yamt/features/shoppinglist/provider/'
    'shopping_list_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

import 'meal_template_detail_helpers.dart';
import 'meal_template_detail_ingredient_card.dart';

Future<void> selectInventoryAssignments({
  required BuildContext context,
  required IngredientRowData row,
  required List<InventoryItem> inventoryItems,
  required void Function(MealTemplateIngredientAssignmentSelection selection)
  onAssignmentChanged,
}) async {
  final selection = await showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      return _IngredientAssignmentBottomSheet(
        row: row,
        inventoryItems: inventoryItems,
      );
    },
  );
  if (!context.mounted || selection == null) {
    return;
  }

  final selectedItems = _selectedInventoryItems(
    selectedItemIds: selection.toSet(),
    inventoryItems: inventoryItems,
  );
  final selectedAmountUnit = resolveSharedAmountProgressUnit(selectedItems);
  final requiresConversion =
      row.requirement?.unit == TemplateIngredientUnit.piece &&
      selectedAmountUnit != null;

  if (!requiresConversion) {
    onAssignmentChanged(
      MealTemplateIngredientAssignmentSelection(
        inventoryItemIds: selection,
      ),
    );
    return;
  }

  final savedConversion = row.amountConversion;
  final initialAmount = savedConversion?.unit == selectedAmountUnit
      ? savedConversion!.amountPerPiece
      : null;
  final amountConversion = await _selectAssignmentConversion(
    context: context,
    row: row,
    targetUnit: selectedAmountUnit,
    initialAmount: initialAmount,
  );
  if (!context.mounted || amountConversion == null) {
    return;
  }

  onAssignmentChanged(
    MealTemplateIngredientAssignmentSelection(
      inventoryItemIds: selection,
      amountConversion: amountConversion,
    ),
  );
}

class _IngredientAssignmentBottomSheet extends StatefulWidget {
  const _IngredientAssignmentBottomSheet({
    required this.row,
    required this.inventoryItems,
  });

  final IngredientRowData row;
  final List<InventoryItem> inventoryItems;

  @override
  State<_IngredientAssignmentBottomSheet> createState() =>
      _IngredientAssignmentBottomSheetState();
}

class _IngredientAssignmentBottomSheetState
    extends State<_IngredientAssignmentBottomSheet> {
  late final Set<String> _draftSelection;
  late final Set<String> _availableItemIds;

  @override
  void initState() {
    super.initState();
    _draftSelection = _normalizedDialogSelectionIds(
      row: widget.row,
      inventoryItems: widget.inventoryItems,
    ).toSet();
    _availableItemIds = widget.inventoryItems
        .map((item) => item.id.trim())
        .where((itemId) => itemId.isNotEmpty)
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortedItems = rankInventoryItemsForIngredient(
      ingredient: widget.row.name,
      inventoryItems: widget.inventoryItems,
      localeCode: l10n.localeName,
    );
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final selectedItems = _selectedInventoryItems(
      selectedItemIds: _draftSelection,
      inventoryItems: widget.inventoryItems,
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.preparedMealTemplateDetailSelectionTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.row.name,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: sortedItems.isEmpty
                    ? Center(
                        child: Text(
                          l10n.preparedMealTemplateDetailSelectionEmpty,
                        ),
                      )
                    : ListView.builder(
                        itemCount: sortedItems.length,
                        itemBuilder: (context, index) {
                          final item = sortedItems[index];
                          final isSelected = _draftSelection.contains(item.id);
                          final isSelectable =
                              canSelectInventoryItemForRequirement(
                                requirement: widget.row.requirement,
                                selectedItems: selectedItems,
                                candidate: item,
                              );

                          return AppCheckboxListTile(
                            value: isSelected,
                            contentPadding: EdgeInsets.zero,
                            secondary: IngredientPreviewThumbnail(
                              imageUrl: item.imageUrl,
                            ),
                            title: Text(item.name),
                            subtitle: Text(inventoryAmountLabel(item)),
                            onChanged: isSelected
                                ? (_) => _toggleSelection(item.id, false)
                                : !isSelectable
                                ? null
                                : (_) => _toggleSelection(item.id, true),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.inventoryReceiptReviewCancelAction),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(
                      _draftSelection
                          .where(_availableItemIds.contains)
                          .toList(growable: false),
                    ),
                    child: Text(
                      l10n.inventoryReceiptReviewManualDataSaveAction,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleSelection(String itemId, bool shouldSelect) {
    setState(() {
      if (shouldSelect) {
        _draftSelection.add(itemId);
      } else {
        _draftSelection.remove(itemId);
      }
    });
  }
}

Future<RecipeIngredientAmountConversion?> _selectAssignmentConversion({
  required BuildContext context,
  required IngredientRowData row,
  required InventoryAmountUnit targetUnit,
  required int? initialAmount,
}) async {
  return showModalBottomSheet<RecipeIngredientAmountConversion>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      return _IngredientAssignmentConversionSheet(
        row: row,
        targetUnit: targetUnit,
        initialAmount: initialAmount,
      );
    },
  );
}

class _IngredientAssignmentConversionSheet extends StatefulWidget {
  const _IngredientAssignmentConversionSheet({
    required this.row,
    required this.targetUnit,
    required this.initialAmount,
  });

  final IngredientRowData row;
  final InventoryAmountUnit targetUnit;
  final int? initialAmount;

  @override
  State<_IngredientAssignmentConversionSheet> createState() =>
      _IngredientAssignmentConversionSheetState();
}

class _IngredientAssignmentConversionSheetState
    extends State<_IngredientAssignmentConversionSheet> {
  late final TextEditingController _conversionController;

  @override
  void initState() {
    super.initState();
    _conversionController = TextEditingController(
      text: widget.initialAmount?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _conversionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.5;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final conversionSourceUnit = conversionSourceUnitLabel(
      requirement: widget.row.requirement,
      l10n: l10n,
    );

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _conversionController,
          builder: (context, value, _) {
            final conversionAmount = int.tryParse(value.text.trim());
            final isConversionValid =
                conversionAmount != null && conversionAmount > 0;
            final conversionErrorText =
                l10n.preparedMealTemplateDetailSelectionConversionError;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.row.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _conversionController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n
                          .preparedMealTemplateDetailSelectionConversionLabel(
                            conversionSourceUnit,
                            widget.targetUnit.code,
                          ),
                      helperText: l10n
                          .preparedMealTemplateDetailSelectionConversionHint(
                            conversionSourceUnit,
                            widget.targetUnit.code,
                            widget.row.name,
                          ),
                      errorText: value.text.trim().isEmpty || isConversionValid
                          ? null
                          : conversionErrorText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(l10n.inventoryReceiptReviewCancelAction),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: !isConversionValid
                            ? null
                            : () => Navigator.of(context).pop(
                                RecipeIngredientAmountConversion(
                                  amountPerPiece: conversionAmount,
                                  unit: widget.targetUnit,
                                ),
                              ),
                        child: Text(
                          l10n.inventoryReceiptReviewManualDataSaveAction,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

List<String> _normalizedDialogSelectionIds({
  required IngredientRowData row,
  required List<InventoryItem> inventoryItems,
}) {
  final availableItemIds = inventoryItems
      .map((item) => item.id.trim())
      .where((itemId) => itemId.isNotEmpty)
      .toSet();
  final selectedItemIds = row.assignedInventoryItemIds
      .where(availableItemIds.contains)
      .toList(growable: false);
  if (selectedItemIds.isEmpty || row.requirement == null) {
    return selectedItemIds;
  }

  final selectedItems = _selectedInventoryItems(
    selectedItemIds: selectedItemIds.toSet(),
    inventoryItems: inventoryItems,
  );
  final effectiveRequirement = resolveEffectiveRequirementForItems(
    requirement: row.requirement!,
    assignedItems: selectedItems,
    amountConversion: row.amountConversion,
  );
  if (effectiveRequirement == null) {
    return const <String>[];
  }
  return selectedItemIds;
}

List<InventoryItem> _selectedInventoryItems({
  required Set<String> selectedItemIds,
  required List<InventoryItem> inventoryItems,
}) {
  final inventoryItemsById = <String, InventoryItem>{
    for (final item in inventoryItems) item.id.trim(): item,
  };
  return selectedItemIds
      .map((itemId) => inventoryItemsById[itemId.trim()])
      .whereType<InventoryItem>()
      .toList(growable: false);
}

Future<void> addIngredientToShoppingList({
  required BuildContext context,
  required WidgetRef ref,
  required String? shoppingListLabel,
}) async {
  if (shoppingListLabel == null || shoppingListLabel.trim().isEmpty) {
    return;
  }
  final added = await ref
      .read(shoppingListControllerProvider.notifier)
      .addItem(name: shoppingListLabel);
  if (!context.mounted || added) {
    return;
  }

  showSnackBar(
    context,
    AppLocalizations.of(
      context,
    )!.preparedMealTemplateDetailAddIngredientShoppingFailed,
  );
}

Future<void> addTemplateIngredientsToShoppingList({
  required BuildContext context,
  required WidgetRef ref,
  required List<IngredientRowData> ingredientRows,
  required List<InventoryItem> inventoryItems,
}) async {
  final labelsToAdd = ingredientRows
      .map(
        (row) =>
            shoppingListLabelForRow(row: row, inventoryItems: inventoryItems),
      )
      .whereType<String>()
      .where((label) => label.trim().isNotEmpty)
      .toList(growable: false);
  if (labelsToAdd.isEmpty) {
    return;
  }

  final controller = ref.read(shoppingListControllerProvider.notifier);
  var addedCount = 0;

  for (final label in labelsToAdd) {
    final added = await controller.addItem(name: label);
    if (!context.mounted) {
      return;
    }
    if (!added) {
      showSnackBar(
        context,
        AppLocalizations.of(
          context,
        )!.preparedMealTemplateDetailAddIngredientsShoppingFailed,
      );
      return;
    }
    addedCount += 1;
  }

  showSnackBar(
    context,
    AppLocalizations.of(
      context,
    )!.preparedMealTemplateDetailAddIngredientsShoppingSucceeded(addedCount),
  );
}

Future<void> toggleIgnored({
  required BuildContext context,
  required WidgetRef ref,
  required String templateId,
  required String ingredient,
  required bool isIgnored,
}) async {
  final updated = await ref
      .read(preparedMealTemplatesControllerProvider.notifier)
      .setRecipeIngredientIgnored(
        templateId: templateId,
        ingredient: ingredient,
        isIgnored: isIgnored,
      );
  if (!context.mounted || updated) {
    return;
  }

  showSnackBar(
    context,
    AppLocalizations.of(context)!.preparedMealTemplateDetailIgnoreSaveFailed,
  );
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
