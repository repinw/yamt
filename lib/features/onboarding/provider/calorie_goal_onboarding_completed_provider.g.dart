// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_onboarding_completed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie goal onboarding completed.

@ProviderFor(calorieGoalOnboardingCompleted)
final calorieGoalOnboardingCompletedProvider =
    CalorieGoalOnboardingCompletedProvider._();

/// Calorie goal onboarding completed.

final class CalorieGoalOnboardingCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Calorie goal onboarding completed.
  CalorieGoalOnboardingCompletedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieGoalOnboardingCompletedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieGoalOnboardingCompletedHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return calorieGoalOnboardingCompleted(ref);
  }
}

String _$calorieGoalOnboardingCompletedHash() =>
    r'ca537ac4909d12f239e89e514218d7c8ece9b1b9';
