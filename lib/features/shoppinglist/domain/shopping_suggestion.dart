import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_planned_meal.dart';

/// A product proposed by a data-owning feature. Equal by value.
@immutable
class ShoppingSuggestion {
  /// Creates a shopping suggestion without coupling to inventory models.
  const new({
    required this.name,
    this.brand,
    this.purchaseCount = 0,
    this.isLowStock = false,
    this.isOutOfStock = false,
    this.plannedFor,
  });

  /// Product name.
  final String name;

  /// Optional brand.
  final String? brand;

  /// Distinct recorded purchases.
  final int purchaseCount;

  /// Whether remaining stock is low.
  final bool isLowStock;

  /// Whether no stock remains.
  final bool isOutOfStock;

  /// The first planned meal that needs the product and the stock cannot
  /// cover; null for a suggestion from the stock alone.
  final ShoppingPlannedMeal? plannedFor;

  @override
  bool operator ==(Object other) =>
      other is ShoppingSuggestion &&
      other.name == name &&
      other.brand == brand &&
      other.purchaseCount == purchaseCount &&
      other.isLowStock == isLowStock &&
      other.isOutOfStock == isOutOfStock &&
      other.plannedFor == plannedFor;

  @override
  int get hashCode => Object.hash(
    name,
    brand,
    purchaseCount,
    isLowStock,
    isOutOfStock,
    plannedFor,
  );
}

/// Suggestions as one immutable value, equal when the suggestions are, so
/// it can key a provider.
@immutable
class ShoppingSuggestionList {
  /// Holds a copy of [suggestions].
  new(List<ShoppingSuggestion> suggestions)
    : items = List.unmodifiable(suggestions);

  static const _equality = ListEquality<ShoppingSuggestion>();

  /// The suggestions, in order.
  final List<ShoppingSuggestion> items;

  @override
  bool operator ==(Object other) =>
      other is ShoppingSuggestionList && _equality.equals(other.items, items);

  @override
  int get hashCode => _equality.hash(items);
}
