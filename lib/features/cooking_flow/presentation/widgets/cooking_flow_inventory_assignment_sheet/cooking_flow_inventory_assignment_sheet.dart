import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_inventory_assignment_sheet/cooking_flow_inventory_assignment_preview.dart';
import 'package:yamt/features/cooking_flow/presentation/widgets/cooking_flow_inventory_assignment_sheet/cooking_flow_manual_ingredient_sheet.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Opens the assignment sheet; returns the chosen items, or null on cancel.
Future<List<CookingFlowInventoryAssignmentSelection>?>
showCookingFlowInventoryAssignmentSheet({
  required BuildContext context,
  required String ingredient,
  required List<InventoryItem> inventoryItems,
  required String localeCode,
  required List<CookingFlowInventoryAssignmentSelection> initialSelections,
}) {
  return showModalBottomSheet<List<CookingFlowInventoryAssignmentSelection>>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      return CookingFlowInventoryAssignmentBottomSheet(
        ingredient: ingredient,
        inventoryItems: inventoryItems,
        localeCode: localeCode,
        initialSelections: initialSelections,
      );
    },
  );
}

/// Sheet that assigns Vorrat items to one recipe ingredient.
class CookingFlowInventoryAssignmentBottomSheet extends StatefulWidget {
  /// Creates the sheet.
  const new({
    required this.ingredient,
    required this.inventoryItems,
    required this.localeCode,
    required this.initialSelections,
    super.key,
  });

  /// Ingredient the items are for.
  final String ingredient;

  /// Vorrat items to choose from.
  final List<InventoryItem> inventoryItems;

  /// Locale for ranking and amounts.
  final String localeCode;

  /// Selections made before.
  final List<CookingFlowInventoryAssignmentSelection> initialSelections;

  @override
  State<CookingFlowInventoryAssignmentBottomSheet> createState() =>
      _CookingFlowInventoryAssignmentBottomSheetState();
}

class _CookingFlowInventoryAssignmentBottomSheetState
    extends State<CookingFlowInventoryAssignmentBottomSheet> {
  late final Set<String> _selectedItemIds;
  late final List<CookingFlowInventoryAssignmentSelection> _manualSelections;
  late List<InventoryItem> _rankedItems;

  @override
  void initState() {
    super.initState();
    _selectedItemIds = <String>{};
    _manualSelections = <CookingFlowInventoryAssignmentSelection>[];
    _rankedItems = _rankInventoryItems();
    for (final selection in widget.initialSelections) {
      if (selection.isAdditionalIngredient) {
        _manualSelections.add(selection);
        continue;
      }
      _selectedItemIds.add(selection.itemId);
    }
  }

  @override
  void didUpdateWidget(
    covariant CookingFlowInventoryAssignmentBottomSheet oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ingredient != widget.ingredient ||
        oldWidget.localeCode != widget.localeCode ||
        oldWidget.inventoryItems != widget.inventoryItems) {
      _rankedItems = _rankInventoryItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortedItems = _rankedItems;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.8;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.cookflowInventorySelectionTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.ingredient,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: sortedItems.isEmpty
                    ? Center(child: Text(l10n.cookflowInventorySelectionEmpty))
                    : ListView.builder(
                        itemCount:
                            sortedItems.length + _manualSelections.length + 1,
                        itemBuilder: (context, index) {
                          final addIngredientSubtitle = l10n
                              .cookflowInventorySelectionAddIngredientSubtitle;
                          if (index < sortedItems.length) {
                            final item = sortedItems[index];
                            final isSelected = _selectedItemIds.contains(
                              item.id,
                            );
                            return AppCheckboxListTile(
                              value: isSelected,
                              contentPadding: EdgeInsets.zero,
                              secondary: CookingFlowInventoryAssignmentPreview(
                                label: item.name,
                                imageUrl: item.imageUrl,
                              ),
                              title: Text(item.name),
                              subtitle: Text(
                                cookingFlowInventoryAmountLabel(item),
                              ),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked ?? false) {
                                    _selectedItemIds.add(item.id);
                                  } else {
                                    _selectedItemIds.remove(item.id);
                                  }
                                });
                              },
                            );
                          }

                          final manualIndex = index - sortedItems.length;
                          if (manualIndex < _manualSelections.length) {
                            final selection = _manualSelections[manualIndex];
                            final item = _inventoryItemById(selection.itemId);
                            return Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CookingFlowInventoryAssignmentPreview(
                                  label:
                                      item?.name ??
                                      l10n.cookflowInventorySelectionItemLabel,
                                  imageUrl: item?.imageUrl,
                                ),
                                title: Text(
                                  item?.name ??
                                      l10n.cookflowInventorySelectionItemLabel,
                                ),
                                subtitle: Text(
                                  l10n.cookflowInventorySelectionWeightLater,
                                ),
                                trailing: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _manualSelections.removeAt(manualIndex);
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            );
                          }

                          return Material(
                            type: MaterialType.transparency,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              title: Text(
                                l10n.cookflowInventorySelectionAddIngredient,
                              ),
                              subtitle: Text(addIngredientSubtitle),
                              onTap: _addManualSelection,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cookflowCancelButton),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed:
                        _selectedItemIds.isEmpty && _manualSelections.isEmpty
                        ? null
                        : () =>
                              Navigator.of(context)
                                  .pop(_buildSelectionResult()),
                    child: Text(l10n.cookflowInventorySelectionSaveButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<CookingFlowInventoryAssignmentSelection> _buildSelectionResult() {
    final baseSelections = _selectedItemIds
        .map(
          (itemId) => CookingFlowInventoryAssignmentSelection(itemId: itemId),
        )
        .toList(growable: false);
    return <CookingFlowInventoryAssignmentSelection>[
      ...baseSelections,
      ..._manualSelections,
    ];
  }

  InventoryItem? _inventoryItemById(String itemId) {
    for (final item in widget.inventoryItems) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  List<InventoryItem> _rankInventoryItems() {
    return rankInventoryItemsForIngredient(
      ingredient: widget.ingredient,
      inventoryItems: widget.inventoryItems,
      localeCode: widget.localeCode,
    );
  }

  Future<void> _addManualSelection() async {
    final selection =
        await showModalBottomSheet<CookingFlowInventoryAssignmentSelection>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          builder: (sheetContext) {
            return CookingFlowManualIngredientSheet(
              inventoryItems: widget.inventoryItems,
            );
          },
        );
    if (!mounted || selection == null) {
      return;
    }

    setState(() {
      _manualSelections
        ..removeWhere((entry) => entry.itemId == selection.itemId)
        ..add(selection);
    });
  }
}
