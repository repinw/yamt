// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_serving_suggestion_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory serving suggestion service provider.

@ProviderFor(inventoryServingSuggestionService)
final inventoryServingSuggestionServiceProvider =
    InventoryServingSuggestionServiceProvider._();

/// The inventory serving suggestion service provider.

final class InventoryServingSuggestionServiceProvider
    extends
        $FunctionalProvider<
          InventoryServingSuggestionService,
          InventoryServingSuggestionService,
          InventoryServingSuggestionService
        >
    with $Provider<InventoryServingSuggestionService> {
  /// The inventory serving suggestion service provider.
  InventoryServingSuggestionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryServingSuggestionServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$inventoryServingSuggestionServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryServingSuggestionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryServingSuggestionService create(Ref ref) {
    return inventoryServingSuggestionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryServingSuggestionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryServingSuggestionService>(
        value,
      ),
    );
  }
}

String _$inventoryServingSuggestionServiceHash() =>
    r'5276f69f1d2f39a0c93c62aa13903dccb0fd66e9';
