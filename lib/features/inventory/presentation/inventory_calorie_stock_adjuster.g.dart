// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_calorie_stock_adjuster.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Inventory-enabled stock adjustment for changed calorie entry amounts.
///
/// Items measured in grams or milliliters consume and return the difference.
/// Items counted in pieces keep their stock: a piece is used up no matter how
/// the estimated amount behind it changes.

@ProviderFor(inventoryCalorieStockAdjuster)
final inventoryCalorieStockAdjusterProvider =
    InventoryCalorieStockAdjusterProvider._();

/// Inventory-enabled stock adjustment for changed calorie entry amounts.
///
/// Items measured in grams or milliliters consume and return the difference.
/// Items counted in pieces keep their stock: a piece is used up no matter how
/// the estimated amount behind it changes.

final class InventoryCalorieStockAdjusterProvider
    extends
        $FunctionalProvider<
          CalorieInventoryStockAdjuster,
          CalorieInventoryStockAdjuster,
          CalorieInventoryStockAdjuster
        >
    with $Provider<CalorieInventoryStockAdjuster> {
  /// Inventory-enabled stock adjustment for changed calorie entry amounts.
  ///
  /// Items measured in grams or milliliters consume and return the difference.
  /// Items counted in pieces keep their stock: a piece is used up no matter how
  /// the estimated amount behind it changes.
  InventoryCalorieStockAdjusterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryCalorieStockAdjusterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryCalorieStockAdjusterHash();

  @$internal
  @override
  $ProviderElement<CalorieInventoryStockAdjuster> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieInventoryStockAdjuster create(Ref ref) {
    return inventoryCalorieStockAdjuster(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieInventoryStockAdjuster value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieInventoryStockAdjuster>(
        value,
      ),
    );
  }
}

String _$inventoryCalorieStockAdjusterHash() =>
    r'2a4aa58f4a983911fa88e70d4ce3f3fe872223aa';
