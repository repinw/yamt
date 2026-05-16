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
        dependencies: <ProviderOrFamily>[cookingFlowControllerProvider],
        $allTransitiveDependencies: <ProviderOrFamily>{
          CookingFlowWizardControllerProvider.$allTransitiveDependencies0,
          CookingFlowWizardControllerProvider.$allTransitiveDependencies1,
          CookingFlowWizardControllerProvider.$allTransitiveDependencies2,
          CookingFlowWizardControllerProvider.$allTransitiveDependencies3,
          CookingFlowWizardControllerProvider.$allTransitiveDependencies4,
          CookingFlowWizardControllerProvider.$allTransitiveDependencies5,
          CookingFlowWizardControllerProvider.$allTransitiveDependencies6,
        },
      );

  static final $allTransitiveDependencies0 = cookingFlowControllerProvider;
  static final $allTransitiveDependencies1 =
      CookingFlowControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      CookingFlowControllerProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      CookingFlowControllerProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      CookingFlowControllerProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies5 =
      CookingFlowControllerProvider.$allTransitiveDependencies4;
  static final $allTransitiveDependencies6 =
      CookingFlowControllerProvider.$allTransitiveDependencies5;

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
    r'cb7edfe605c338c46b9cd4629efeeb77e171473a';

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
