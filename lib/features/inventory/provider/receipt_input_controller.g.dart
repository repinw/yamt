// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_input_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReceiptInputController)
final receiptInputControllerProvider = ReceiptInputControllerProvider._();

final class ReceiptInputControllerProvider
    extends
        $AsyncNotifierProvider<ReceiptInputController, ReceiptInputResult?> {
  ReceiptInputControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptInputControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptInputControllerHash();

  @$internal
  @override
  ReceiptInputController create() => ReceiptInputController();
}

String _$receiptInputControllerHash() =>
    r'709bd220d0a9d89252b6cbda040a06a18ca05bdf';

abstract class _$ReceiptInputController
    extends $AsyncNotifier<ReceiptInputResult?> {
  FutureOr<ReceiptInputResult?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<ReceiptInputResult?>, ReceiptInputResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ReceiptInputResult?>, ReceiptInputResult?>,
              AsyncValue<ReceiptInputResult?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
