// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_calorie_entry_commit_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory calorie entry commit store provider.

@ProviderFor(inventoryCalorieEntryCommitStore)
final inventoryCalorieEntryCommitStoreProvider =
    InventoryCalorieEntryCommitStoreProvider._();

/// The inventory calorie entry commit store provider.

final class InventoryCalorieEntryCommitStoreProvider
    extends
        $FunctionalProvider<
          InventoryCalorieEntryCommitStore,
          InventoryCalorieEntryCommitStore,
          InventoryCalorieEntryCommitStore
        >
    with $Provider<InventoryCalorieEntryCommitStore> {
  /// The inventory calorie entry commit store provider.
  InventoryCalorieEntryCommitStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryCalorieEntryCommitStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryCalorieEntryCommitStoreHash();

  @$internal
  @override
  $ProviderElement<InventoryCalorieEntryCommitStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryCalorieEntryCommitStore create(Ref ref) {
    return inventoryCalorieEntryCommitStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryCalorieEntryCommitStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryCalorieEntryCommitStore>(
        value,
      ),
    );
  }
}

String _$inventoryCalorieEntryCommitStoreHash() =>
    r'9d6024bcec1a4aec8a32b1872c67bc302c2c1a36';
