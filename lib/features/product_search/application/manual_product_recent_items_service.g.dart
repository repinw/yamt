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
        dependencies: <ProviderOrFamily>[inventoryItemRepositoryProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ManualProductRecentItemsServiceProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;

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
    r'551d3ab48924ea15d887efbcd4c93a3971c229c5';
