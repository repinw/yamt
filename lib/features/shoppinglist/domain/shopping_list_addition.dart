import 'package:yamt/features/shoppinglist/domain/shopping_list_item.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_planned_meal.dart';

/// Pure normalization and merging for shopping-list additions.
class ShoppingListAddition {
  /// Creates an addition helper.
  const new();

  /// Validates names and normalizes quantities and prices.
  ShoppingListAddInput? parseAddItemInput({
    required String name,
    required int quantity,
    required double estimatedUnitPrice,
    String? brand,
    String? note,
    ShoppingPlannedMeal? plannedFor,
    bool isPrivate = false,
  }) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return null;
    final trimmedBrand = brand?.trim();
    final trimmedNote = note?.trim();
    return ShoppingListAddInput(
      name: trimmedName,
      brand: trimmedBrand?.isEmpty ?? true ? null : trimmedBrand,
      note: trimmedNote?.isEmpty ?? true ? null : trimmedNote,
      plannedFor: plannedFor,
      quantity: quantity < 1 ? 1 : quantity,
      estimatedUnitPrice: estimatedUnitPrice.isFinite && estimatedUnitPrice > 0
          ? estimatedUnitPrice
          : 0,
      isPrivate: isPrivate,
    );
  }

  /// Merges by normalized name and brand within the same list, household or
  /// private. An entry that is still to buy gets
  /// the quantity on top; a ticked-off or archived one comes back with the
  /// new quantity alone. A note or planned meal of the addition replaces the
  /// old one.
  List<ShoppingListItem> mergeAddedItem({
    required List<ShoppingListItem> previousItems,
    required ShoppingListAddInput input,
    required String generatedId,
  }) {
    final index = previousItems.indexWhere(
      (item) =>
          item.isPrivate == input.isPrivate &&
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
    quantity: (current.isOpen ? current.quantity : 0) + input.quantity,
    isArchived: false,
    isDone: false,
    // An entry that comes back takes the new note and meal, or none.
    note: input.note,
    clearNote: !current.isOpen && input.note == null,
    plannedFor: input.plannedFor,
    clearPlannedFor: !current.isOpen && input.plannedFor == null,
    estimatedUnitPrice: input.estimatedUnitPrice > 0
        ? input.estimatedUnitPrice
        : current.estimatedUnitPrice,
  );
}

/// Validated addition payload.
class ShoppingListAddInput {
  /// Creates validated input.
  const new({
    required this.name,
    required this.brand,
    required this.quantity,
    required this.estimatedUnitPrice,
    this.note,
    this.plannedFor,
    this.isPrivate = false,
  });

  /// Trimmed product name.
  final String name;

  /// Trimmed optional brand.
  final String? brand;

  /// Positive quantity.
  final int quantity;

  /// Trimmed optional note.
  final String? note;

  /// The planned meal the entry is for.
  final ShoppingPlannedMeal? plannedFor;

  /// Nonnegative price.
  final double estimatedUnitPrice;

  /// Whether the entry goes on the private list.
  final bool isPrivate;

  /// Case-insensitive product name.
  String get normalizedName => name.toLowerCase();

  /// Case-insensitive brand.
  String get normalizedBrand => brand?.toLowerCase() ?? '';

  /// Creates a new ordinary shopping entry.
  ShoppingListItem toItem(String id) => ShoppingListItem(
    id: id,
    name: name,
    brand: brand,
    note: note,
    plannedFor: plannedFor,
    normalizedName: normalizedName,
    normalizedBrand: normalizedBrand,
    quantity: quantity,
    estimatedUnitPrice: estimatedUnitPrice,
    isPrivate: isPrivate,
  );
}
