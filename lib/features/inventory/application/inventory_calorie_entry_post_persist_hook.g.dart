// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_calorie_entry_post_persist_hook.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The inventory calorie entry post persist hook provider.

@ProviderFor(inventoryCalorieEntryPostPersistHook)
final inventoryCalorieEntryPostPersistHookProvider =
    InventoryCalorieEntryPostPersistHookProvider._();

/// The inventory calorie entry post persist hook provider.

final class InventoryCalorieEntryPostPersistHookProvider
    extends
        $FunctionalProvider<
          CalorieEntryPostPersistHook,
          CalorieEntryPostPersistHook,
          CalorieEntryPostPersistHook
        >
    with $Provider<CalorieEntryPostPersistHook> {
  /// The inventory calorie entry post persist hook provider.
  InventoryCalorieEntryPostPersistHookProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryCalorieEntryPostPersistHookProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$inventoryCalorieEntryPostPersistHookHash();

  @$internal
  @override
  $ProviderElement<CalorieEntryPostPersistHook> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieEntryPostPersistHook create(Ref ref) {
    return inventoryCalorieEntryPostPersistHook(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieEntryPostPersistHook value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieEntryPostPersistHook>(value),
    );
  }
}

String _$inventoryCalorieEntryPostPersistHookHash() =>
    r'e22870bfedf97201257812776e26826cc5194351';
