import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/inventory_stock_add_page.dart';
import 'package:yamt/features/inventory/presentation/models/inventory_stock_add_result.dart';

/// Opens the page that puts the new product [item] into the Vorrat. With
/// [offersEat], the page also offers to eat or plan it instead.
Future<InventoryStockAddResult?> showInventoryStockAddPage({
  required BuildContext context,
  required InventoryItem item,
  int initialPackages = 1,
  bool offersEat = false,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute<InventoryStockAddResult>(
      fullscreenDialog: true,
      builder: (_) => InventoryStockAddPage(
        item: item,
        initialPackages: initialPackages,
        offersEat: offersEat,
      ),
    ),
  );
}
