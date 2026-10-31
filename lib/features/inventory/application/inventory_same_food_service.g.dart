// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_same_food_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The same food service.

@ProviderFor(inventorySameFoodService)
final inventorySameFoodServiceProvider = InventorySameFoodServiceProvider._();

/// The same food service.

final class InventorySameFoodServiceProvider
    extends
        $FunctionalProvider<
          InventorySameFoodService,
          InventorySameFoodService,
          InventorySameFoodService
        >
    with $Provider<InventorySameFoodService> {
  /// The same food service.
  InventorySameFoodServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventorySameFoodServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventorySameFoodServiceHash();

  @$internal
  @override
  $ProviderElement<InventorySameFoodService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventorySameFoodService create(Ref ref) {
    return inventorySameFoodService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventorySameFoodService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventorySameFoodService>(value),
    );
  }
}

String _$inventorySameFoodServiceHash() =>
    r'4f16f01be48fa36b033106ea0fb7ed65f69e8bbb';
