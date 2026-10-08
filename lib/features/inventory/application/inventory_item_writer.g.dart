// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_item_writer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Vorrat item writer provider.

@ProviderFor(inventoryItemWriter)
final inventoryItemWriterProvider = InventoryItemWriterProvider._();

/// The Vorrat item writer provider.

final class InventoryItemWriterProvider
    extends
        $FunctionalProvider<
          InventoryItemWriter,
          InventoryItemWriter,
          InventoryItemWriter
        >
    with $Provider<InventoryItemWriter> {
  /// The Vorrat item writer provider.
  InventoryItemWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryItemWriterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryItemWriterHash();

  @$internal
  @override
  $ProviderElement<InventoryItemWriter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InventoryItemWriter create(Ref ref) {
    return inventoryItemWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InventoryItemWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InventoryItemWriter>(value),
    );
  }
}

String _$inventoryItemWriterHash() =>
    r'57be2c11f2eaec5ed1fdc4afa96b7869ad6eecea';
