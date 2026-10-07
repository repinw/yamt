// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_shopping_suggestions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live stock input owned by inventory.

@ProviderFor(inventoryShoppingStock)
final inventoryShoppingStockProvider = InventoryShoppingStockProvider._();

/// Live stock input owned by inventory.

final class InventoryShoppingStockProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryItem>>,
          List<InventoryItem>,
          Stream<List<InventoryItem>>
        >
    with
        $FutureModifier<List<InventoryItem>>,
        $StreamProvider<List<InventoryItem>> {
  /// Live stock input owned by inventory.
  InventoryShoppingStockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryShoppingStockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryShoppingStockHash();

  @$internal
  @override
  $StreamProviderElement<List<InventoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InventoryItem>> create(Ref ref) {
    return inventoryShoppingStock(ref);
  }
}

String _$inventoryShoppingStockHash() =>
    r'1993b1c6398648a54e67959730f5c6c9e54bf2c3';

/// Adapts inventory facts to the shopping feature's public suggestion model.

@ProviderFor(inventoryShoppingSuggestions)
final inventoryShoppingSuggestionsProvider =
    InventoryShoppingSuggestionsProvider._();

/// Adapts inventory facts to the shopping feature's public suggestion model.

final class InventoryShoppingSuggestionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingSuggestion>>,
          AsyncValue<List<ShoppingSuggestion>>,
          AsyncValue<List<ShoppingSuggestion>>
        >
    with $Provider<AsyncValue<List<ShoppingSuggestion>>> {
  /// Adapts inventory facts to the shopping feature's public suggestion model.
  InventoryShoppingSuggestionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryShoppingSuggestionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryShoppingSuggestionsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<ShoppingSuggestion>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<ShoppingSuggestion>> create(Ref ref) {
    return inventoryShoppingSuggestions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<ShoppingSuggestion>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<ShoppingSuggestion>>>(value),
    );
  }
}

String _$inventoryShoppingSuggestionsHash() =>
    r'c38cb70171abf04a1df05460f4a8c158d7c594ae';

/// What to buy for the open plans the Vorrat cannot cover, grouped by day
/// and meal, without the foods already on the shopping list.
// ponytail: plans of found foods and cooked meals are left out like in the
// demand; add them when the demand counts them.

@ProviderFor(inventoryShoppingPlanNeedGroups)
final inventoryShoppingPlanNeedGroupsProvider =
    InventoryShoppingPlanNeedGroupsProvider._();

/// What to buy for the open plans the Vorrat cannot cover, grouped by day
/// and meal, without the foods already on the shopping list.
// ponytail: plans of found foods and cooked meals are left out like in the
// demand; add them when the demand counts them.

final class InventoryShoppingPlanNeedGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ShoppingPlanNeedGroup>>,
          List<ShoppingPlanNeedGroup>,
          FutureOr<List<ShoppingPlanNeedGroup>>
        >
    with
        $FutureModifier<List<ShoppingPlanNeedGroup>>,
        $FutureProvider<List<ShoppingPlanNeedGroup>> {
  /// What to buy for the open plans the Vorrat cannot cover, grouped by day
  /// and meal, without the foods already on the shopping list.
  // ponytail: plans of found foods and cooked meals are left out like in the
  // demand; add them when the demand counts them.
  InventoryShoppingPlanNeedGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryShoppingPlanNeedGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryShoppingPlanNeedGroupsHash();

  @$internal
  @override
  $FutureProviderElement<List<ShoppingPlanNeedGroup>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ShoppingPlanNeedGroup>> create(Ref ref) {
    return inventoryShoppingPlanNeedGroups(ref);
  }
}

String _$inventoryShoppingPlanNeedGroupsHash() =>
    r'7b6ae1ee7c08c553a5545c0154ddff07dd7bf13e';
