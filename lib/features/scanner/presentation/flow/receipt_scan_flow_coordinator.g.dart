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
        dependencies: null,
        $allTransitiveDependencies: null,
      );

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
    r'cc8b06bee4e0b5c415301d5fcbbc500f80250b9f';
