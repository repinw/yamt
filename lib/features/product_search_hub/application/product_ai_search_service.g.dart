// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_ai_search_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application service for generating AI product drafts.

@ProviderFor(productAiSearchService)
final productAiSearchServiceProvider = ProductAiSearchServiceProvider._();

/// Application service for generating AI product drafts.

final class ProductAiSearchServiceProvider
    extends
        $FunctionalProvider<
          ProductAiSearchService,
          ProductAiSearchService,
          ProductAiSearchService
        >
    with $Provider<ProductAiSearchService> {
  /// Application service for generating AI product drafts.
  ProductAiSearchServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productAiSearchServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productAiSearchServiceHash();

  @$internal
  @override
  $ProviderElement<ProductAiSearchService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ProductAiSearchService create(Ref ref) {
    return productAiSearchService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProductAiSearchService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProductAiSearchService>(value),
    );
  }
}

String _$productAiSearchServiceHash() =>
    r'cb0e2a700fcfd2c7d6a7eb8061b61ffb6e27adf9';
