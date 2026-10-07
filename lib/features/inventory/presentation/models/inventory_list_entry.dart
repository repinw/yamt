import 'package:yamt/core/constants/app_graphit_constants.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

/// First letter of [name] in upper case, the picture of an entry without an
/// image; null for an empty name.
String? inventoryPictureLetter(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty
      ? null
      : String.fromCharCode(trimmed.runes.first).toUpperCase();
}

/// One row of the flat Vorrat list: a food or a prepared meal.
sealed class InventoryListEntry {
  const new();

  /// Stable id for list keys.
  String get id;

  /// Name shown in the row.
  String get name;

  /// When the entry was added to the Vorrat.
  DateTime get addedAt;

  /// When the entry was last eaten from, if known.
  DateTime? get lastEatenAt;

  /// Remaining stock from 0 (empty) to 1 (as bought or cooked).
  double get remainingShare;

  /// Packs of a food or portions of a meal; one stock bar segment each.
  int get segments;

  /// Whether nothing is left.
  bool get isEmpty;

  /// Whether part of it is used and some is left.
  bool get isOpen;

  /// Whether less than a quarter is left, but not nothing.
  bool get isLow => !isEmpty && remainingShare < AppGraphit.lowStockShare;
}

/// A food of the Vorrat.
final class InventoryFoodEntry extends InventoryListEntry {
  /// Creates the entry for [item].
  const new(this.item);

  /// The food.
  final InventoryItem item;

  @override
  String get id => item.id;

  @override
  String get name => item.name;

  @override
  DateTime get addedAt => item.entryDate;

  @override
  DateTime? get lastEatenAt => item.lastConsumedAt;

  @override
  double get remainingShare =>
      shareOf(item.usesAmountProgress ? item.currentAmount : item.quantity);

  /// [amount] of stock, in the stored unit, as a share of the full stock.
  double shareOf(int amount) {
    final full = item.usesAmountProgress
        ? item.initialAmount
        : item.effectiveInitialQuantity;
    return amount.clamp(0, full) / full;
  }

  @override
  int get segments => item.effectiveInitialQuantity;

  @override
  bool get isEmpty => item.isFullyConsumed;

  @override
  bool get isOpen => item.isConsumed && !item.isFullyConsumed;
}

/// A prepared meal of the Vorrat.
final class InventoryMealEntry extends InventoryListEntry {
  /// Creates the entry for [meal].
  const new(this.meal);

  /// The meal.
  final PreparedMeal meal;

  @override
  String get id => meal.id;

  @override
  String get name => meal.name;

  @override
  DateTime get addedAt => meal.createdAt;

  /// Meals do not record when they were eaten; every portion eaten updates
  /// the meal.
  @override
  DateTime? get lastEatenAt => meal.updatedAt;

  @override
  double get remainingShare => meal.remainingRatio.clamp(0.0, 1.0);

  @override
  int get segments => meal.totalPortions < 1 ? 1 : meal.totalPortions;

  @override
  bool get isEmpty => meal.isDepleted;

  @override
  bool get isOpen =>
      !meal.isDepleted && meal.remainingPortions < meal.totalPortions;
}
