import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

part 'shopping_list_controller.g.dart';

@riverpod
class ShoppingListController extends _$ShoppingListController {
  @override
  List<ShoppingListItem> build() {
    return const <ShoppingListItem>[];
  }

  bool addItem({
    required String name,
    String? brand,
    int quantity = 1,
    double estimatedUnitPrice = 0.0,
  }) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    final safePrice = estimatedUnitPrice < 0 ? 0.0 : estimatedUnitPrice;
    final trimmedName = name.trim();
    final trimmedBrand = brand?.trim();
    final normalizedName = _normalize(trimmedName);
    final normalizedBrand = _normalize(trimmedBrand ?? '');
    if (normalizedName.isEmpty) {
      return false;
    }

    final existingIndex = state.indexWhere((item) {
      return item.normalizedName == normalizedName &&
          item.normalizedBrand == normalizedBrand;
    });

    if (existingIndex < 0) {
      state = <ShoppingListItem>[
        ...state,
        ShoppingListItem(
          id: _nextId(),
          name: trimmedName,
          brand: trimmedBrand,
          normalizedName: normalizedName,
          normalizedBrand: normalizedBrand,
          quantity: safeQuantity,
          estimatedUnitPrice: safePrice,
        ),
      ];
      return true;
    }

    final updated = List<ShoppingListItem>.from(state);
    final current = updated[existingIndex];
    updated[existingIndex] = current.copyWith(
      quantity: current.quantity + safeQuantity,
      estimatedUnitPrice: safePrice > 0
          ? safePrice
          : current.estimatedUnitPrice,
    );
    state = updated;
    return true;
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.id != itemId).toList(growable: false);
  }

  void incrementQuantity(String itemId) {
    _updateQuantity(itemId, (quantity) => quantity + 1);
  }

  void decrementQuantity(String itemId) {
    _updateQuantity(itemId, (quantity) => quantity - 1);
  }

  void _updateQuantity(String itemId, int Function(int quantity) transform) {
    final index = state.indexWhere((item) => item.id == itemId);
    if (index < 0) {
      return;
    }

    final items = List<ShoppingListItem>.from(state);
    final item = items[index];
    final nextQuantity = transform(item.quantity);
    if (nextQuantity < 1) {
      items.removeAt(index);
      state = items;
      return;
    }

    items[index] = item.copyWith(quantity: nextQuantity);
    state = items;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  String _nextId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
