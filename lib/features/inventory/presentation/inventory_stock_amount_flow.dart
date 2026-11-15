import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_amount_page.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_stock_count.dart';

/// Asks on [InventoryStockAmountPage] how much of [item] the cook has at
/// home for a recipe line measured in [lineUnit] that needs [need]; a piece
/// without a weight starts with [pieceWeight].
///
/// Returns the count, or null when the cook closes the page.
Future<InventoryStockCount?> countInventoryStockForRecipe(
  BuildContext context, {
  required InventoryItem item,
  InventoryAmountUnit? lineUnit,
  int? need,
  int? pieceWeight,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<InventoryStockCount>(
      builder: (_) => InventoryStockAmountPage(
        item: item,
        lineUnit: lineUnit,
        need: need,
        pieceWeight: pieceWeight,
      ),
    ),
  );
}
