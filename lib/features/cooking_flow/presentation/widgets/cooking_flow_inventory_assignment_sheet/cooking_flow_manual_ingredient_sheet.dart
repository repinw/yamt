import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/widgets/app_dropdown_button.dart';
import 'package:yamt/features/cooking_flow/application/cooking_flow_intro_inventory_models.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Sheet that adds one Vorrat item as an extra ingredient.
class CookingFlowManualIngredientSheet extends StatefulWidget {
  /// Creates the sheet.
  const new({required this.inventoryItems, super.key});

  /// Vorrat items to choose from.
  final List<InventoryItem> inventoryItems;

  @override
  State<CookingFlowManualIngredientSheet> createState() =>
      _CookingFlowManualIngredientSheetState();
}

class _CookingFlowManualIngredientSheetState
    extends State<CookingFlowManualIngredientSheet> {
  String? _selectedItemId;
  late List<InventoryItem> _sortedItems;

  @override
  void initState() {
    super.initState();
    _sortedItems = _sortInventoryItems(widget.inventoryItems);
  }

  @override
  void didUpdateWidget(covariant CookingFlowManualIngredientSheet oldWidget) {
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
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
  }
}
