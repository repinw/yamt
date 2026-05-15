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
        dependencies: <ProviderOrFamily>[
          inventoryItemRepositoryProvider,
          preparedMealsControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          CookingFlowControllerProvider.$allTransitiveDependencies0,
          CookingFlowControllerProvider.$allTransitiveDependencies1,
          CookingFlowControllerProvider.$allTransitiveDependencies2,
          CookingFlowControllerProvider.$allTransitiveDependencies3,
          CookingFlowControllerProvider.$allTransitiveDependencies4,
        },
      );

  static final $allTransitiveDependencies0 = inventoryItemRepositoryProvider;
  static final $allTransitiveDependencies1 = preparedMealsControllerProvider;
  static final $allTransitiveDependencies2 =
      PreparedMealsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 =
      PreparedMealsControllerProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      PreparedMealsControllerProvider.$allTransitiveDependencies3;

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
    r'910363c5505b0515e84483217cb66636ec7bfe98';

/// Controls cookflow business actions.

abstract class _$CookingFlowController
    extends $Notifier<CookingFlowControllerState> {
  CookingFlowControllerState build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
