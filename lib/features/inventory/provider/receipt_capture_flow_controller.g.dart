// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_capture_flow_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReceiptCaptureFlowController)
final receiptCaptureFlowControllerProvider =
    ReceiptCaptureFlowControllerProvider._();

final class ReceiptCaptureFlowControllerProvider
    extends
        $AsyncNotifierProvider<
          ReceiptCaptureFlowController,
          ReceiptCaptureFlowResult?
        > {
  ReceiptCaptureFlowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptCaptureFlowControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptCaptureFlowControllerHash();

  @$internal
  @override
  ReceiptCaptureFlowController create() => ReceiptCaptureFlowController();
}

String _$receiptCaptureFlowControllerHash() =>
    r'6b852718049d81217e47c7ed54926fc9ddeeadc1';

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
