// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_analysis_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ReceiptAnalysisController)
final receiptAnalysisControllerProvider = ReceiptAnalysisControllerProvider._();

final class ReceiptAnalysisControllerProvider
    extends
        $AsyncNotifierProvider<
          ReceiptAnalysisController,
          ReceiptAnalysisResult?
        > {
  ReceiptAnalysisControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receiptAnalysisControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receiptAnalysisControllerHash();

  @$internal
  @override
  ReceiptAnalysisController create() => ReceiptAnalysisController();
}

String _$receiptAnalysisControllerHash() =>
    r'ffc9d7e3f6711d8a8572ea78c82e21d8e0191b0c';

abstract class _$ReceiptAnalysisController
    extends $AsyncNotifier<ReceiptAnalysisResult?> {
  FutureOr<ReceiptAnalysisResult?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<ReceiptAnalysisResult?>, ReceiptAnalysisResult?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<ReceiptAnalysisResult?>,
                ReceiptAnalysisResult?
              >,
              AsyncValue<ReceiptAnalysisResult?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
