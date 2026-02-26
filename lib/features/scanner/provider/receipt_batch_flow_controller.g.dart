// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_batch_flow_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReceiptBatchFlowController)
final receiptBatchFlowControllerProvider =
    ReceiptBatchFlowControllerProvider._();

final class ReceiptBatchFlowControllerProvider
    extends
        $NotifierProvider<ReceiptBatchFlowController, ReceiptBatchFlowState> {
  ReceiptBatchFlowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptBatchFlowControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptBatchFlowControllerHash();

  @$internal
  @override
  ReceiptBatchFlowController create() => ReceiptBatchFlowController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReceiptBatchFlowState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReceiptBatchFlowState>(value),
    );
  }
}

String _$receiptBatchFlowControllerHash() =>
    r'ad1b2b9c1704534402e1ee9b920538febb6852d5';

abstract class _$ReceiptBatchFlowController
    extends $Notifier<ReceiptBatchFlowState> {
  ReceiptBatchFlowState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ReceiptBatchFlowState, ReceiptBatchFlowState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ReceiptBatchFlowState, ReceiptBatchFlowState>,
              ReceiptBatchFlowState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
