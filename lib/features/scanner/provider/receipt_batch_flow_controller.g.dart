// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_batch_flow_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines receipt batch flow controller.

@ProviderFor(ReceiptBatchFlowController)
final receiptBatchFlowControllerProvider =
    ReceiptBatchFlowControllerProvider._();

/// Defines receipt batch flow controller.
final class ReceiptBatchFlowControllerProvider
    extends
        $NotifierProvider<ReceiptBatchFlowController, ReceiptBatchFlowState> {
  /// Defines receipt batch flow controller.
  ReceiptBatchFlowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptBatchFlowControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          receiptReviewResolutionServiceProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ReceiptBatchFlowControllerProvider.$allTransitiveDependencies0,
          ReceiptBatchFlowControllerProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 =
      receiptReviewResolutionServiceProvider;
  static final $allTransitiveDependencies1 =
      ReceiptReviewResolutionServiceProvider.$allTransitiveDependencies0;

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
    r'71c4052c6e20f94fe0c344dde84b6653106d1d6c';

/// Defines receipt batch flow controller.

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
