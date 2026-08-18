// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_inventory_entry_save_handler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides inventory-backed calorie entry persistence when inventory is wired.

@ProviderFor(calorieInventoryEntrySaveHandler)
final calorieInventoryEntrySaveHandlerProvider =
    CalorieInventoryEntrySaveHandlerProvider._();

/// Provides inventory-backed calorie entry persistence when inventory is wired.

final class CalorieInventoryEntrySaveHandlerProvider
    extends
        $FunctionalProvider<
          CalorieInventoryEntrySaveHandler?,
          CalorieInventoryEntrySaveHandler?,
          CalorieInventoryEntrySaveHandler?
        >
    with $Provider<CalorieInventoryEntrySaveHandler?> {
  /// Provides inventory-backed calorie entry persistence when inventory is wired.
  CalorieInventoryEntrySaveHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieInventoryEntrySaveHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieInventoryEntrySaveHandlerHash();

  @$internal
  @override
  $ProviderElement<CalorieInventoryEntrySaveHandler?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieInventoryEntrySaveHandler? create(Ref ref) {
    return calorieInventoryEntrySaveHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieInventoryEntrySaveHandler? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieInventoryEntrySaveHandler?>(
        value,
      ),
    );
  }
}

String _$calorieInventoryEntrySaveHandlerHash() =>
    r'5682cc2dd126bda52c99fe8dee1c8927750969b6';

/// Provides cleanup for pending inventory consumption when inventory is wired.

@ProviderFor(calorieInventoryPendingConsumptionDiscarder)
final calorieInventoryPendingConsumptionDiscarderProvider =
    CalorieInventoryPendingConsumptionDiscarderProvider._();

/// Provides cleanup for pending inventory consumption when inventory is wired.

final class CalorieInventoryPendingConsumptionDiscarderProvider
    extends
        $FunctionalProvider<
          CalorieInventoryPendingConsumptionDiscarder?,
          CalorieInventoryPendingConsumptionDiscarder?,
          CalorieInventoryPendingConsumptionDiscarder?
        >
    with $Provider<CalorieInventoryPendingConsumptionDiscarder?> {
  /// Provides cleanup for pending inventory consumption when inventory is wired.
  CalorieInventoryPendingConsumptionDiscarderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieInventoryPendingConsumptionDiscarderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$calorieInventoryPendingConsumptionDiscarderHash();

  @$internal
  @override
  $ProviderElement<CalorieInventoryPendingConsumptionDiscarder?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieInventoryPendingConsumptionDiscarder? create(Ref ref) {
    return calorieInventoryPendingConsumptionDiscarder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(
    CalorieInventoryPendingConsumptionDiscarder? value,
  ) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<CalorieInventoryPendingConsumptionDiscarder?>(
            value,
          ),
    );
  }
}

String _$calorieInventoryPendingConsumptionDiscarderHash() =>
    r'45260b2a245ad46625141a560d6b9c4351596b12';
