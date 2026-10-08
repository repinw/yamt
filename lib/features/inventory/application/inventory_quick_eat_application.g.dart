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
    r'36400cae0bcbda6906083590e170652f721beeb4';
