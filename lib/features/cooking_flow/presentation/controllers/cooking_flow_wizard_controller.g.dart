// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cooking_flow_wizard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Controls cookflow wizard state and session persistence.

@ProviderFor(CookingFlowWizardController)
final cookingFlowWizardControllerProvider =
    CookingFlowWizardControllerProvider._();

/// Controls cookflow wizard state and session persistence.
final class CookingFlowWizardControllerProvider
    extends
        $NotifierProvider<CookingFlowWizardController, CookingFlowWizardState> {
  /// Controls cookflow wizard state and session persistence.
  CookingFlowWizardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cookingFlowWizardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cookingFlowWizardControllerHash();

  @$internal
  @override
  CookingFlowWizardController create() => CookingFlowWizardController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CookingFlowWizardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CookingFlowWizardState>(value),
    );
  }
}

String _$cookingFlowWizardControllerHash() =>
    r'6a2ab7e3c81d2f795d7f6cae45b32772c36c87d0';

/// Controls cookflow wizard state and session persistence.

abstract class _$CookingFlowWizardController
    extends $Notifier<CookingFlowWizardState> {
  CookingFlowWizardState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<CookingFlowWizardState, CookingFlowWizardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CookingFlowWizardState, CookingFlowWizardState>,
              CookingFlowWizardState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
