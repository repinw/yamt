// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_to_fridge_item_mapper.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(receiptToFridgeItemMapper)
final receiptToFridgeItemMapperProvider = ReceiptToFridgeItemMapperProvider._();

final class ReceiptToFridgeItemMapperProvider
    extends
        $FunctionalProvider<
          ReceiptToFridgeItemMapper,
          ReceiptToFridgeItemMapper,
          ReceiptToFridgeItemMapper
        >
    with $Provider<ReceiptToFridgeItemMapper> {
  ReceiptToFridgeItemMapperProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptToFridgeItemMapperProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptToFridgeItemMapperHash();

  @$internal
  @override
  $ProviderElement<ReceiptToFridgeItemMapper> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptToFridgeItemMapper create(Ref ref) {
    return receiptToFridgeItemMapper(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptToFridgeItemMapper value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptToFridgeItemMapper>(value),
    );
  }
}

String _$receiptToFridgeItemMapperHash() =>
    r'ede97325bddcd4cead7c35c7df32c9a94db6a32a';
