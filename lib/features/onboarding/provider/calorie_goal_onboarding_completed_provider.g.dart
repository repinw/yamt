// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_onboarding_completed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie goal onboarding completed.
///
/// The user id comes from the data key session, not from the auth state. The
/// settings repository depends on the same session, so after an account
/// switch the provider rebuilds once and never reads the settings of the new
/// user with the data key of the previous one.

@ProviderFor(calorieGoalOnboardingCompleted)
final calorieGoalOnboardingCompletedProvider =
    CalorieGoalOnboardingCompletedProvider._();

/// Calorie goal onboarding completed.
///
/// The user id comes from the data key session, not from the auth state. The
/// settings repository depends on the same session, so after an account
/// switch the provider rebuilds once and never reads the settings of the new
/// user with the data key of the previous one.

final class CalorieGoalOnboardingCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Calorie goal onboarding completed.
  ///
  /// The user id comes from the data key session, not from the auth state. The
  /// settings repository depends on the same session, so after an account
  /// switch the provider rebuilds once and never reads the settings of the new
  /// user with the data key of the previous one.
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
    r'ee25b511462ab935c9582156ee29d1bed57be000';
