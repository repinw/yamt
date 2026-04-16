// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_capture_flow_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Defines receipt capture flow controller.

@ProviderFor(ReceiptCaptureFlowController)
final receiptCaptureFlowControllerProvider =
    ReceiptCaptureFlowControllerProvider._();

/// Defines receipt capture flow controller.
final class ReceiptCaptureFlowControllerProvider
    extends
        $AsyncNotifierProvider<
          ReceiptCaptureFlowController,
          ReceiptCaptureFlowResult?
        > {
  /// Defines receipt capture flow controller.
  ReceiptCaptureFlowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptCaptureFlowControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          receiptReviewResolutionServiceProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ReceiptCaptureFlowControllerProvider.$allTransitiveDependencies0,
          ReceiptCaptureFlowControllerProvider.$allTransitiveDependencies1,
        ],
      );

  static final $allTransitiveDependencies0 =
      receiptReviewResolutionServiceProvider;
  static final $allTransitiveDependencies1 =
      ReceiptReviewResolutionServiceProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$receiptCaptureFlowControllerHash();

  @$internal
  @override
  ReceiptCaptureFlowController create() => ReceiptCaptureFlowController();
}

String _$receiptCaptureFlowControllerHash() =>
    r'434e1c061ce9255fa087c36011496f9f926d4872';

/// Defines receipt capture flow controller.

abstract class _$ReceiptCaptureFlowController
    extends $AsyncNotifier<ReceiptCaptureFlowResult?> {
  FutureOr<ReceiptCaptureFlowResult?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<ReceiptCaptureFlowResult?>,
              ReceiptCaptureFlowResult?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ReceiptCaptureFlowResult?>,
                ReceiptCaptureFlowResult?
              >,
              AsyncValue<ReceiptCaptureFlowResult?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
