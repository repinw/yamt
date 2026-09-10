import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';

/// Pure normalization and merging for shopping-list additions.
class ShoppingListAddition {
  /// Creates an addition helper.
  const ShoppingListAddition();

  /// Validates names and normalizes quantities and prices.
  ShoppingListAddInput? parseAddItemInput({
    required String name,
    required int quantity,
    required double estimatedUnitPrice,
    String? brand,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;
    final trimmedBrand = brand?.trim();
    return ShoppingListAddInput(
      name: trimmedName,
      brand: trimmedBrand?.isEmpty ?? true ? null : trimmedBrand,
      quantity: quantity < 1 ? 1 : quantity,
      estimatedUnitPrice: estimatedUnitPrice.isFinite && estimatedUnitPrice > 0
          ? estimatedUnitPrice
          : 0,
    );
  }

  /// Merges by normalized name and brand, reactivating saved entries.
  List<ShoppingListItem> mergeAddedItem({
    required List<ShoppingListItem> previousItems,
    required ShoppingListAddInput input,
    required String generatedId,
  }) {
    final index = previousItems.indexWhere(
      (item) =>
          item.normalizedName == input.normalizedName &&
          item.normalizedBrand == input.normalizedBrand,
    );
    if (index < 0) return [...previousItems, input.toItem(generatedId)];
    final next = List<ShoppingListItem>.from(previousItems);
    next[index] = _merge(next[index], input);
    return next;
  }

  ShoppingListItem _merge(
    ShoppingListItem current,
    ShoppingListAddInput input,
  ) => current.copyWith(
    quantity: (current.isArchived ? 0 : current.quantity) + input.quantity,
    isArchived: false,
    estimatedUnitPrice: input.estimatedUnitPrice > 0
        ? input.estimatedUnitPrice
        : current.estimatedUnitPrice,
  );
}

/// Validated addition payload.
class ShoppingListAddInput {
  /// Creates validated input.
  const ShoppingListAddInput({
    required this.name,
    required this.brand,
    required this.quantity,
    required this.estimatedUnitPrice,
  });

  /// Trimmed product name.
  final String name;

  /// Trimmed optional brand.
  final String? brand;

  /// Positive quantity.
  final int quantity;

  /// Nonnegative price.
  final double estimatedUnitPrice;

  /// Case-insensitive product name.
  String get normalizedName => name.toLowerCase();

  /// Case-insensitive brand.
  String get normalizedBrand => brand?.toLowerCase() ?? '';

  /// Creates a new ordinary shopping entry.
  ShoppingListItem toItem(String id) => ShoppingListItem(
    id: id,
    name: name,
    brand: brand,
    normalizedName: normalizedName,
    normalizedBrand: normalizedBrand,
    quantity: quantity,
    estimatedUnitPrice: estimatedUnitPrice,
  );
}
