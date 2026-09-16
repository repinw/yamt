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
    r'cab527c6d989dc0e223716ae72df366e4ba81d5d';

/// Controls cookflow wizard state and session persistence.

abstract class _$CookingFlowWizardController
    extends $Notifier<CookingFlowWizardState> {
  CookingFlowWizardState build();
  @$mustCallSuper
  @override
  void runBuild() {
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
    element.handleCreate(ref, build);
  }
}
