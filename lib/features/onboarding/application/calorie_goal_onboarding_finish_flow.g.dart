// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_onboarding_finish_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Onboarding-owned flow for saving the initial calorie goal.

@ProviderFor(calorieGoalOnboardingFinishFlow)
final calorieGoalOnboardingFinishFlowProvider =
    CalorieGoalOnboardingFinishFlowProvider._();

/// Onboarding-owned flow for saving the initial calorie goal.

final class CalorieGoalOnboardingFinishFlowProvider
    extends
        $FunctionalProvider<
          CalorieGoalOnboardingFinishFlow,
          CalorieGoalOnboardingFinishFlow,
          CalorieGoalOnboardingFinishFlow
        >
    with $Provider<CalorieGoalOnboardingFinishFlow> {
  /// Onboarding-owned flow for saving the initial calorie goal.
  CalorieGoalOnboardingFinishFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieGoalOnboardingFinishFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieGoalOnboardingFinishFlowHash();

  @$internal
  @override
  $ProviderElement<CalorieGoalOnboardingFinishFlow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieGoalOnboardingFinishFlow create(Ref ref) {
    return calorieGoalOnboardingFinishFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieGoalOnboardingFinishFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieGoalOnboardingFinishFlow>(
        value,
      ),
    );
  }
}

String _$calorieGoalOnboardingFinishFlowHash() =>
    r'89bb74726ed14627e5c0f053fd23bddb13244ad9';
