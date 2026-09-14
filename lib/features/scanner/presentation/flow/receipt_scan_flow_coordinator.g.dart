// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_scan_flow_coordinator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for [ReceiptScanFlowCoordinator].

@ProviderFor(receiptScanFlowCoordinator)
final receiptScanFlowCoordinatorProvider =
    ReceiptScanFlowCoordinatorProvider._();

/// Provider for [ReceiptScanFlowCoordinator].

final class ReceiptScanFlowCoordinatorProvider
    extends
        $FunctionalProvider<
          ReceiptScanFlowCoordinator,
          ReceiptScanFlowCoordinator,
          ReceiptScanFlowCoordinator
        >
    with $Provider<ReceiptScanFlowCoordinator> {
  /// Provider for [ReceiptScanFlowCoordinator].
  ReceiptScanFlowCoordinatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptScanFlowCoordinatorProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          receiptStructuredParserProvider,
          receiptTextExtractorProvider,
          receiptProductResolverProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ReceiptScanFlowCoordinatorProvider.$allTransitiveDependencies0,
          ReceiptScanFlowCoordinatorProvider.$allTransitiveDependencies1,
          ReceiptScanFlowCoordinatorProvider.$allTransitiveDependencies2,
        ],
      );

  static final $allTransitiveDependencies0 = receiptStructuredParserProvider;
  static final $allTransitiveDependencies1 = receiptTextExtractorProvider;
  static final $allTransitiveDependencies2 = receiptProductResolverProvider;

  @override
  String debugGetCreateSourceHash() => _$receiptScanFlowCoordinatorHash();

  @$internal
  @override
  $ProviderElement<ReceiptScanFlowCoordinator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReceiptScanFlowCoordinator create(Ref ref) {
    return receiptScanFlowCoordinator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptScanFlowCoordinator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptScanFlowCoordinator>(value),
    );
  }
}

String _$receiptScanFlowCoordinatorHash() =>
    r'c33af3a123b882cda60bcbe94add9fc55fe5af2f';
