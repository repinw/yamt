// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_product_search_page_route.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// In-memory payload store for internal product-search child routes.

@ProviderFor(manualProductSearchRoutePayloadStore)
final manualProductSearchRoutePayloadStoreProvider =
    ManualProductSearchRoutePayloadStoreProvider._();

/// In-memory payload store for internal product-search child routes.

final class ManualProductSearchRoutePayloadStoreProvider
    extends
        $FunctionalProvider<
          ManualProductSearchRoutePayloadStore,
          ManualProductSearchRoutePayloadStore,
          ManualProductSearchRoutePayloadStore
        >
    with $Provider<ManualProductSearchRoutePayloadStore> {
  /// In-memory payload store for internal product-search child routes.
  ManualProductSearchRoutePayloadStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualProductSearchRoutePayloadStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$manualProductSearchRoutePayloadStoreHash();

  @$internal
  @override
  $ProviderElement<ManualProductSearchRoutePayloadStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ManualProductSearchRoutePayloadStore create(Ref ref) {
    return manualProductSearchRoutePayloadStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualProductSearchRoutePayloadStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<ManualProductSearchRoutePayloadStore>(value),
    );
  }
}

String _$manualProductSearchRoutePayloadStoreHash() =>
    r'62d2b812ef873349a47944b000d47a391a34e237';
