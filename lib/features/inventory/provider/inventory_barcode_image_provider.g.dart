// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_barcode_image_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inventoryBarcodeImageUrl)
final inventoryBarcodeImageUrlProvider = InventoryBarcodeImageUrlFamily._();

final class InventoryBarcodeImageUrlProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  InventoryBarcodeImageUrlProvider._({
    required InventoryBarcodeImageUrlFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'inventoryBarcodeImageUrlProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$inventoryBarcodeImageUrlHash();

  @override
  String toString() {
    return r'inventoryBarcodeImageUrlProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return inventoryBarcodeImageUrl(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InventoryBarcodeImageUrlProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$inventoryBarcodeImageUrlHash() =>
    r'825aa4fc5b6eb90824e26ca46af2c37e20f741a3';

final class InventoryBarcodeImageUrlFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  InventoryBarcodeImageUrlFamily._()
    : super(
        retry: null,
        name: r'inventoryBarcodeImageUrlProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  InventoryBarcodeImageUrlProvider call(String rawBarcode) =>
      InventoryBarcodeImageUrlProvider._(argument: rawBarcode, from: this);

  @override
  String toString() => r'inventoryBarcodeImageUrlProvider';
}
