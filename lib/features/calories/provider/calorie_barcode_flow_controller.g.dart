// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_barcode_flow_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CalorieBarcodeFlowController)
final calorieBarcodeFlowControllerProvider =
    CalorieBarcodeFlowControllerProvider._();

final class CalorieBarcodeFlowControllerProvider
    extends
        $AsyncNotifierProvider<
          CalorieBarcodeFlowController,
          CalorieLookupOutcome?
        > {
  CalorieBarcodeFlowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieBarcodeFlowControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieBarcodeFlowControllerHash();

  @$internal
  @override
  CalorieBarcodeFlowController create() => CalorieBarcodeFlowController();
}

String _$calorieBarcodeFlowControllerHash() =>
    r'80ad192cbd828b1567c95e8fba3c5a099546aeec';

abstract class _$CalorieBarcodeFlowController
    extends $AsyncNotifier<CalorieLookupOutcome?> {
  FutureOr<CalorieLookupOutcome?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<CalorieLookupOutcome?>, CalorieLookupOutcome?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CalorieLookupOutcome?>,
                CalorieLookupOutcome?
              >,
              AsyncValue<CalorieLookupOutcome?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
