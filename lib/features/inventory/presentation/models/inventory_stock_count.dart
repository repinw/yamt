import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// What the amount page returns: the food as the cook counted it (a typed
/// pack weight or piece count already in it) and its stock in the food's
/// stored unit.
typedef InventoryStockCount = ({InventoryItem item, int amount});
