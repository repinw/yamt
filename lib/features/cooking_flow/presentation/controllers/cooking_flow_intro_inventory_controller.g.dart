// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_flow_intro_inventory_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls intro inventory assignment state.

@ProviderFor(CookingFlowIntroInventoryController)
final cookingFlowIntroInventoryControllerProvider =
    CookingFlowIntroInventoryControllerProvider._();

/// Controls intro inventory assignment state.
final class CookingFlowIntroInventoryControllerProvider
    extends
        $NotifierProvider<
          CookingFlowIntroInventoryController,
          CookingFlowIntroInventoryState
        > {
  /// Controls intro inventory assignment state.
  CookingFlowIntroInventoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookingFlowIntroInventoryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$cookingFlowIntroInventoryControllerHash();

  @$internal
  @override
  CookingFlowIntroInventoryController create() =>
      CookingFlowIntroInventoryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookingFlowIntroInventoryState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookingFlowIntroInventoryState>(
        value,
      ),
    );
  }
}

String _$cookingFlowIntroInventoryControllerHash() =>
    r'fa1377dbdf4f4b488004d29f50524fd115763fcd';

/// Controls intro inventory assignment state.

abstract class _$CookingFlowIntroInventoryController
    extends $Notifier<CookingFlowIntroInventoryState> {
  CookingFlowIntroInventoryState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              CookingFlowIntroInventoryState,
              CookingFlowIntroInventoryState
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                CookingFlowIntroInventoryState,
                CookingFlowIntroInventoryState
              >,
              CookingFlowIntroInventoryState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
