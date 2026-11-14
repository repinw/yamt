import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/preferences/app_preferences.dart';

part 'shopping_list_order_controller.g.dart';

const _orderKey = 'shopping_list_order_v1';

/// How the list lays its entries out.
enum ShoppingListOrder {
  /// Grouped by shelf, in the order of the way through the shop.
  byShelf,

  /// By name, from A to Z.
  byName,
}

/// The order of the list, saved on the device. By shelf until the user
/// switches.
@riverpod
class ShoppingListOrderController extends _$ShoppingListOrderController {
  @override
  ShoppingListOrder build() {
    final stored = ref.watch(appPreferencesProvider).getStringSync(_orderKey);
    return ShoppingListOrder.values.asNameMap()[stored] ??
        ShoppingListOrder.byShelf;
  }

  /// Switches between the two orders and saves the choice.
  Future<void> toggle() async {
    final link = ref.keepAlive();
    try {
      final next = state == ShoppingListOrder.byShelf
          ? ShoppingListOrder.byName
          : ShoppingListOrder.byShelf;
      state = next;
      await ref.read(appPreferencesProvider).setString(_orderKey, next.name);
    } finally {
      link.close();
    }
  }
}
