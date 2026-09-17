// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_flow_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls cookflow business actions.

@ProviderFor(CookingFlowController)
final cookingFlowControllerProvider = CookingFlowControllerProvider._();

/// Controls cookflow business actions.
final class CookingFlowControllerProvider
    extends
        $NotifierProvider<CookingFlowController, CookingFlowControllerState> {
  /// Controls cookflow business actions.
  CookingFlowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookingFlowControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookingFlowControllerHash();

  @$internal
  @override
  CookingFlowController create() => CookingFlowController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookingFlowControllerState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookingFlowControllerState>(value),
    );
  }
}

String _$cookingFlowControllerHash() =>
    r'b36bca0bbf2284569bd4486c8f3726cec5195860';

/// Controls cookflow business actions.

abstract class _$CookingFlowController
    extends $Notifier<CookingFlowControllerState> {
  CookingFlowControllerState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<CookingFlowControllerState, CookingFlowControllerState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                CookingFlowControllerState,
                CookingFlowControllerState
              >,
              CookingFlowControllerState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
