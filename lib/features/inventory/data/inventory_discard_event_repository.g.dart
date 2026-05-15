// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_discard_event_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory discard event repository provider.

@ProviderFor(inventoryDiscardEventRepository)
final inventoryDiscardEventRepositoryProvider =
    InventoryDiscardEventRepositoryProvider._();

/// The inventory discard event repository provider.

final class InventoryDiscardEventRepositoryProvider
    extends
        $FunctionalProvider<
          InventoryDiscardEventRepository,
          InventoryDiscardEventRepository,
          InventoryDiscardEventRepository
        >
    with $Provider<InventoryDiscardEventRepository> {
  /// The inventory discard event repository provider.
  InventoryDiscardEventRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryDiscardEventRepositoryProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryDiscardEventRepositoryHash();

  @$internal
  @override
  $ProviderElement<InventoryDiscardEventRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryDiscardEventRepository create(Ref ref) {
    return inventoryDiscardEventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryDiscardEventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryDiscardEventRepository>(
        value,
      ),
    );
  }
}

String _$inventoryDiscardEventRepositoryHash() =>
    r'376f962d2d4b98377025628544a605e86539679b';
