// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_onboarding_wizard_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// State controller for the calorie onboarding wizard.

@ProviderFor(CalorieOnboardingWizardController)
final calorieOnboardingWizardControllerProvider =
    CalorieOnboardingWizardControllerProvider._();

/// State controller for the calorie onboarding wizard.
final class CalorieOnboardingWizardControllerProvider
    extends
        $NotifierProvider<
          CalorieOnboardingWizardController,
          CalorieOnboardingWizardState
        > {
  /// State controller for the calorie onboarding wizard.
  CalorieOnboardingWizardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieOnboardingWizardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$calorieOnboardingWizardControllerHash();

  @$internal
  @override
  CalorieOnboardingWizardController create() =>
      CalorieOnboardingWizardController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieOnboardingWizardState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieOnboardingWizardState>(value),
    );
  }
}

String _$calorieOnboardingWizardControllerHash() =>
    r'7c73215d2d07c646e0e037337d67332fd3641c28';

/// State controller for the calorie onboarding wizard.

abstract class _$CalorieOnboardingWizardController
    extends $Notifier<CalorieOnboardingWizardState> {
  CalorieOnboardingWizardState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<CalorieOnboardingWizardState, CalorieOnboardingWizardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                CalorieOnboardingWizardState,
                CalorieOnboardingWizardState
              >,
              CalorieOnboardingWizardState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
