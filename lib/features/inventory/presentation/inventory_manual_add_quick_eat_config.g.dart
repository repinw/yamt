// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_manual_add_quick_eat_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Scoped provider for quick-eat settings in manual add subtrees.

@ProviderFor(inventoryManualAddQuickEatConfig)
final inventoryManualAddQuickEatConfigProvider =
    InventoryManualAddQuickEatConfigProvider._();

/// Scoped provider for quick-eat settings in manual add subtrees.

final class InventoryManualAddQuickEatConfigProvider
    extends
        $FunctionalProvider<
          InventoryManualAddQuickEatConfig,
          InventoryManualAddQuickEatConfig,
          InventoryManualAddQuickEatConfig
        >
    with $Provider<InventoryManualAddQuickEatConfig> {
  /// Scoped provider for quick-eat settings in manual add subtrees.
  InventoryManualAddQuickEatConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryManualAddQuickEatConfigProvider',
        isAutoDispose: false,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryManualAddQuickEatConfigHash();

  @$internal
  @override
  $ProviderElement<InventoryManualAddQuickEatConfig> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryManualAddQuickEatConfig create(Ref ref) {
    return inventoryManualAddQuickEatConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryManualAddQuickEatConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryManualAddQuickEatConfig>(
        value,
      ),
    );
  }
}

String _$inventoryManualAddQuickEatConfigHash() =>
    r'd182f2f96119df816e60492f8dd09aa6be5fe51d';
