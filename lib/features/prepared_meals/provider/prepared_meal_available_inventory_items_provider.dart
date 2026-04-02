import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/provider/inventory_items_controller.dart';
import 'package:yamt/features/prepared_meals/domain/inventory_item.dart';

final preparedMealAvailableInventoryItemsProvider =
    Provider<List<InventoryItem>>((ref) {
      return ref.watch(inventoryItemsControllerProvider).asData?.value ??
          const <InventoryItem>[];
    });
