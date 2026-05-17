// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_manual_product_search_launcher.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the manual product-search launcher for inventory surfaces.

@ProviderFor(inventoryManualProductSearchLauncher)
final inventoryManualProductSearchLauncherProvider =
    InventoryManualProductSearchLauncherProvider._();

/// Provides the manual product-search launcher for inventory surfaces.

final class InventoryManualProductSearchLauncherProvider
    extends
        $FunctionalProvider<
          InventoryManualProductSearchLauncher,
          InventoryManualProductSearchLauncher,
          InventoryManualProductSearchLauncher
        >
    with $Provider<InventoryManualProductSearchLauncher> {
  /// Provides the manual product-search launcher for inventory surfaces.
  InventoryManualProductSearchLauncherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryManualProductSearchLauncherProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$inventoryManualProductSearchLauncherHash();

  @$internal
  @override
  $ProviderElement<InventoryManualProductSearchLauncher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryManualProductSearchLauncher create(Ref ref) {
    return inventoryManualProductSearchLauncher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryManualProductSearchLauncher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<InventoryManualProductSearchLauncher>(value),
    );
  }
}

String _$inventoryManualProductSearchLauncherHash() =>
    r'40276c05a385a6aed659ca73a6cf4f18a25b9f1d';
