// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_activity_event_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Inventory activity event repository provider.

@ProviderFor(inventoryActivityEventRepository)
final inventoryActivityEventRepositoryProvider =
    InventoryActivityEventRepositoryProvider._();

/// Inventory activity event repository provider.

final class InventoryActivityEventRepositoryProvider
    extends
        $FunctionalProvider<
          InventoryActivityEventRepository,
          InventoryActivityEventRepository,
          InventoryActivityEventRepository
        >
    with $Provider<InventoryActivityEventRepository> {
  /// Inventory activity event repository provider.
  InventoryActivityEventRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryActivityEventRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryActivityEventRepositoryHash();

  @$internal
  @override
  $ProviderElement<InventoryActivityEventRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryActivityEventRepository create(Ref ref) {
    return inventoryActivityEventRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryActivityEventRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryActivityEventRepository>(
        value,
      ),
    );
  }
}

String _$inventoryActivityEventRepositoryHash() =>
    r'c161ea9435f659381199ad0f5bffda3cfc83038b';

/// Current inventory activity actor.

@ProviderFor(inventoryActivityActor)
final inventoryActivityActorProvider = InventoryActivityActorProvider._();

/// Current inventory activity actor.

final class InventoryActivityActorProvider
    extends
        $FunctionalProvider<
          InventoryActivityActor?,
          InventoryActivityActor?,
          InventoryActivityActor?
        >
    with $Provider<InventoryActivityActor?> {
  /// Current inventory activity actor.
  InventoryActivityActorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryActivityActorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryActivityActorHash();

  @$internal
  @override
  $ProviderElement<InventoryActivityActor?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryActivityActor? create(Ref ref) {
    return inventoryActivityActor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryActivityActor? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryActivityActor?>(value),
    );
  }
}

String _$inventoryActivityActorHash() =>
    r'0ba9ad3b17f9f3d47b1ea0be2edb1b684fe8be4e';

/// Recent inventory activity events.

@ProviderFor(inventoryActivityEvents)
final inventoryActivityEventsProvider = InventoryActivityEventsProvider._();

/// Recent inventory activity events.

final class InventoryActivityEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryActivityEvent>>,
          List<InventoryActivityEvent>,
          Stream<List<InventoryActivityEvent>>
        >
    with
        $FutureModifier<List<InventoryActivityEvent>>,
        $StreamProvider<List<InventoryActivityEvent>> {
  /// Recent inventory activity events.
  InventoryActivityEventsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryActivityEventsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryActivityEventsHash();

  @$internal
  @override
  $StreamProviderElement<List<InventoryActivityEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InventoryActivityEvent>> create(Ref ref) {
    return inventoryActivityEvents(ref);
  }
}

String _$inventoryActivityEventsHash() =>
    r'7237326b667e77d3fe09b4d1ad7142981dd1889e';
