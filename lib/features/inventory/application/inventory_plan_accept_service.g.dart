// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_plan_accept_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The plan accept service.

@ProviderFor(inventoryPlanAcceptService)
final inventoryPlanAcceptServiceProvider =
    InventoryPlanAcceptServiceProvider._();

/// The plan accept service.

final class InventoryPlanAcceptServiceProvider
    extends
        $FunctionalProvider<
          InventoryPlanAcceptService,
          InventoryPlanAcceptService,
          InventoryPlanAcceptService
        >
    with $Provider<InventoryPlanAcceptService> {
  /// The plan accept service.
  InventoryPlanAcceptServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryPlanAcceptServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryPlanAcceptServiceHash();

  @$internal
  @override
  $ProviderElement<InventoryPlanAcceptService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryPlanAcceptService create(Ref ref) {
    return inventoryPlanAcceptService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryPlanAcceptService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryPlanAcceptService>(value),
    );
  }
}

String _$inventoryPlanAcceptServiceHash() =>
    r'be1b275902c3aee9851e113863fa56e7581468a7';
