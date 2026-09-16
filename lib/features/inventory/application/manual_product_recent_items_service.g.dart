// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manual_product_recent_items_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Application service for recent manual product candidates.

@ProviderFor(manualProductRecentItemsService)
final manualProductRecentItemsServiceProvider =
    ManualProductRecentItemsServiceProvider._();

/// Application service for recent manual product candidates.

final class ManualProductRecentItemsServiceProvider
    extends
        $FunctionalProvider<
          ManualProductRecentItemsService,
          ManualProductRecentItemsService,
          ManualProductRecentItemsService
        >
    with $Provider<ManualProductRecentItemsService> {
  /// Application service for recent manual product candidates.
  ManualProductRecentItemsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualProductRecentItemsServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualProductRecentItemsServiceHash();

  @$internal
  @override
  $ProviderElement<ManualProductRecentItemsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ManualProductRecentItemsService create(Ref ref) {
    return manualProductRecentItemsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ManualProductRecentItemsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ManualProductRecentItemsService>(
        value,
      ),
    );
  }
}

String _$manualProductRecentItemsServiceHash() =>
    r'90d83b592d7222abdcb665edd8559d398be49d8a';
