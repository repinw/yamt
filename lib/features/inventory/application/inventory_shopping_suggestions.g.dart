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
        dependencies: <ProviderOrFamily>[inventoryItemRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          InventoryShoppingStockProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;

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
    r'b5a2b9fda1cbcb4fb776d55d8bc6a79613cff3b4';

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
        dependencies: <ProviderOrFamily>[inventoryShoppingStockProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          InventoryShoppingSuggestionsProvider.$allTransitiveDependencies0,
          InventoryShoppingSuggestionsProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 = inventoryShoppingStockProvider;
  static final $allTransitiveDependencies1 =
      InventoryShoppingStockProvider.$allTransitiveDependencies0;

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
    r'455104a0a87b6a03c861d52abcb0bb488dc95b1a';
