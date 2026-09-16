// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_quick_eat_application.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Creates repository-backed quick-eat mutations.

@ProviderFor(inventoryQuickEatApplication)
final inventoryQuickEatApplicationProvider =
    InventoryQuickEatApplicationProvider._();

/// Creates repository-backed quick-eat mutations.

final class InventoryQuickEatApplicationProvider
    extends
        $FunctionalProvider<
          InventoryQuickEatApplication,
          InventoryQuickEatApplication,
          InventoryQuickEatApplication
        >
    with $Provider<InventoryQuickEatApplication> {
  /// Creates repository-backed quick-eat mutations.
  InventoryQuickEatApplicationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryQuickEatApplicationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryQuickEatApplicationHash();

  @$internal
  @override
  $ProviderElement<InventoryQuickEatApplication> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryQuickEatApplication create(Ref ref) {
    return inventoryQuickEatApplication(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryQuickEatApplication value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryQuickEatApplication>(value),
    );
  }
}

String _$inventoryQuickEatApplicationHash() =>
    r'b667a521bf63c71221a77040809182f749886049';

/// Provides application-level quick-eat mutations for Inventory callers.

@ProviderFor(inventoryQuickEatActions)
final inventoryQuickEatActionsProvider = InventoryQuickEatActionsProvider._();

/// Provides application-level quick-eat mutations for Inventory callers.

final class InventoryQuickEatActionsProvider
    extends
        $FunctionalProvider<
          InventoryQuickEatActions,
          InventoryQuickEatActions,
          InventoryQuickEatActions
        >
    with $Provider<InventoryQuickEatActions> {
  /// Provides application-level quick-eat mutations for Inventory callers.
  InventoryQuickEatActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryQuickEatActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryQuickEatActionsHash();

  @$internal
  @override
  $ProviderElement<InventoryQuickEatActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryQuickEatActions create(Ref ref) {
    return inventoryQuickEatActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryQuickEatActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryQuickEatActions>(value),
    );
  }
}

String _$inventoryQuickEatActionsHash() =>
    r'cef39c0c037bf269fad62ed499d187836a72ddc2';
