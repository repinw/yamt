// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_product_catalog_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The manual product catalog service provider.

@ProviderFor(manualProductCatalogService)
final manualProductCatalogServiceProvider =
    ManualProductCatalogServiceProvider._();

/// The manual product catalog service provider.

final class ManualProductCatalogServiceProvider
    extends
        $FunctionalProvider<
          ManualProductCatalogService,
          ManualProductCatalogService,
          ManualProductCatalogService
        >
    with $Provider<ManualProductCatalogService> {
  /// The manual product catalog service provider.
  ManualProductCatalogServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualProductCatalogServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualProductCatalogServiceHash();

  @$internal
  @override
  $ProviderElement<ManualProductCatalogService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ManualProductCatalogService create(Ref ref) {
    return manualProductCatalogService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualProductCatalogService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManualProductCatalogService>(value),
    );
  }
}

String _$manualProductCatalogServiceHash() =>
    r'06e281d07056de963e97564d1388262bf3c0c0b1';
