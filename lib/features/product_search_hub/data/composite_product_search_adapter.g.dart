// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'composite_product_search_adapter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the composite search adapter as a [ProductSearchGateway].

@ProviderFor(productSearchGateway)
final productSearchGatewayProvider = ProductSearchGatewayProvider._();

/// Provides the composite search adapter as a [ProductSearchGateway].

final class ProductSearchGatewayProvider
    extends
        $FunctionalProvider<
          ProductSearchGateway,
          ProductSearchGateway,
          ProductSearchGateway
        >
    with $Provider<ProductSearchGateway> {
  /// Provides the composite search adapter as a [ProductSearchGateway].
  ProductSearchGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productSearchGatewayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productSearchGatewayHash();

  @$internal
  @override
  $ProviderElement<ProductSearchGateway> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductSearchGateway create(Ref ref) {
    return productSearchGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductSearchGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductSearchGateway>(value),
    );
  }
}

String _$productSearchGatewayHash() =>
    r'c232462bdde5eb1ea9129601f5adff92392a936e';
