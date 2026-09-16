// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_quick_eat_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Composition root supplies the presentation implementation.

@ProviderFor(inventoryQuickEatPicker)
final inventoryQuickEatPickerProvider = InventoryQuickEatPickerProvider._();

/// Composition root supplies the presentation implementation.

final class InventoryQuickEatPickerProvider
    extends
        $FunctionalProvider<
          InventoryQuickEatPicker,
          InventoryQuickEatPicker,
          InventoryQuickEatPicker
        >
    with $Provider<InventoryQuickEatPicker> {
  /// Composition root supplies the presentation implementation.
  InventoryQuickEatPickerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryQuickEatPickerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryQuickEatPickerHash();

  @$internal
  @override
  $ProviderElement<InventoryQuickEatPicker> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryQuickEatPicker create(Ref ref) {
    return inventoryQuickEatPicker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryQuickEatPicker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryQuickEatPicker>(value),
    );
  }
}

String _$inventoryQuickEatPickerHash() =>
    r'b146d799717ac27663616c318c5db3b904723f2c';
