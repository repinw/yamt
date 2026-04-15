// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_onboarding_completed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieGoalOnboardingCompleted)
final calorieGoalOnboardingCompletedProvider =
    CalorieGoalOnboardingCompletedProvider._();

final class CalorieGoalOnboardingCompletedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
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
    r'dfb7c7819184e1a1fd314f59a69b7200fdb964bc';
