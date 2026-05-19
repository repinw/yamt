// Internal split widgets/helpers are public only for sibling imports.
// ignore_for_file: public_member_api_docs, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/core/widgets/app_selection_list_tiles.dart';
import 'package:yamt/features/cooking_flow/application/'
    'cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/inventory/application/'
    'ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/widgets/prepared_meals/'
    'prepared_meal_cover.dart';
import 'package:yamt/l10n/app_localizations.dart';

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

Future<CookingFlowInventoryCheckRowData?> showCookingFlowIngredientEditSheet({
  required BuildContext context,
  required CookingFlowInventoryCheckRowData row,
}) {
  return showModalBottomSheet<CookingFlowInventoryCheckRowData>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (sheetContext) {
      return _IngredientEditBottomSheet(row: row);
    },
  );
}

class _IngredientEditBottomSheet extends StatefulWidget {
  const _IngredientEditBottomSheet({required this.row});

  final CookingFlowInventoryCheckRowData row;

  @override
  State<_IngredientEditBottomSheet> createState() =>
      _IngredientEditBottomSheetState();
}

class _IngredientEditBottomSheetState
    extends State<_IngredientEditBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    final amountParts = cookingFlowSplitIngredientAmountLabel(
      widget.row.amountLabel,
    );
    _nameController = TextEditingController(text: widget.row.name);
    _amountController = TextEditingController(text: amountParts.amount);
    _unitController = TextEditingController(text: amountParts.unit);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.cookflowEditIngredientTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.cookflowEditIngredientNameLabel,
                ),
                validator: _requiredFieldValidator,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.cookflowEditIngredientAmountLabel,
                      ),
                      validator: _requiredFieldValidator,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: InputDecoration(
                        labelText: l10n.cookflowEditIngredientUnitLabel,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cookflowCancelButton),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _save,
                    child: Text(l10n.cookflowEditIngredientSaveAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredFieldValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppLocalizations.of(context)!.cookflowEditIngredientRequiredField;
    }
    return null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final name = _nameController.text.trim();
    final amount = _amountController.text.trim();
    final unit = _unitController.text.trim();
    Navigator.of(context).pop(
      widget.row.copyWith(
        name: name,
        amountLabel: unit.isEmpty ? amount : '$amount $unit',
        isEdited: true,
      ),
    );
  }
}

class CookingFlowInventoryAssignmentBottomSheet extends StatefulWidget {
  const CookingFlowInventoryAssignmentBottomSheet({
    required this.ingredient,
    required this.inventoryItems,
    required this.localeCode,
    required this.initialSelections,
  });

  final String ingredient;
  final List<InventoryItem> inventoryItems;
  final String localeCode;
  final List<CookingFlowInventoryAssignmentSelection> initialSelections;

  @override
  State<CookingFlowInventoryAssignmentBottomSheet> createState() =>
      CookingFlowInventoryAssignmentBottomSheetState();
}

class CookingFlowInventoryAssignmentBottomSheetState
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
                    ? Center(
                        child: Text(l10n.cookflowInventorySelectionEmpty),
                      )
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
                            return ListTile(
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
                            );
                          }

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.add_circle_outline_rounded,
                            ),
                            title: Text(
                              l10n.cookflowInventorySelectionAddIngredient,
                            ),
                            subtitle: Text(addIngredientSubtitle),
                            onTap: _addManualSelection,
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
                        : () => Navigator.of(context).pop(
                            _buildSelectionResult(),
                          ),
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
            return _ManualIngredientAdditionSheet(
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

class _ManualIngredientAdditionSheet extends StatefulWidget {
  const _ManualIngredientAdditionSheet({
    required this.inventoryItems,
  });

  final List<InventoryItem> inventoryItems;

  @override
  State<_ManualIngredientAdditionSheet> createState() =>
      _ManualIngredientAdditionSheetState();
}

class _ManualIngredientAdditionSheetState
    extends State<_ManualIngredientAdditionSheet> {
  String? _selectedItemId;
  late List<InventoryItem> _sortedItems;

  @override
  void initState() {
    super.initState();
    _sortedItems = _sortInventoryItems(widget.inventoryItems);
  }

  @override
  void didUpdateWidget(covariant _ManualIngredientAdditionSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inventoryItems != widget.inventoryItems) {
      _sortedItems = _sortInventoryItems(widget.inventoryItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortedItems = _sortedItems;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isValid = _selectedItemId != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.cookflowInventorySelectionAddIngredient,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppDropdownButtonFormField<String>(
              initialValue: _selectedItemId,
              decoration: InputDecoration(
                labelText: l10n.cookflowInventorySelectionItemLabel,
              ),
              items: sortedItems
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                setState(() {
                  _selectedItemId = value;
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cookflowCancelButton),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: !isValid
                      ? null
                      : () => Navigator.of(context).pop(
                          CookingFlowInventoryAssignmentSelection(
                            itemId: _selectedItemId!,
                            isAdditionalIngredient: true,
                          ),
                        ),
                  child: Text(l10n.cookflowInventorySelectionAddConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<InventoryItem> _sortInventoryItems(List<InventoryItem> items) {
    return List<InventoryItem>.from(items)..sort(
      (left, right) => left.name.toLowerCase().compareTo(
        right.name.toLowerCase(),
      ),
    );
  }
}

class CookingFlowInventoryAssignmentPreview extends StatelessWidget {
  const CookingFlowInventoryAssignmentPreview({
    required this.label,
    required this.imageUrl,
    this.size = 40,
  });

  final String label;
  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PreparedMealCover(
      label: label,
      imageBytes: null,
      imageUrl: imageUrl,
      size: size,
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
  }
}
