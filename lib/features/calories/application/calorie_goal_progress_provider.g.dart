// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_goal_progress_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Weight and learned TDEE of the goal that is active on [endDate], from its
/// start up to [endDate]. `null` without a goal on [endDate].

@ProviderFor(calorieGoalProgress)
final calorieGoalProgressProvider = CalorieGoalProgressFamily._();

/// Weight and learned TDEE of the goal that is active on [endDate], from its
/// start up to [endDate]. `null` without a goal on [endDate].

final class CalorieGoalProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieGoalProgress?>,
          CalorieGoalProgress?,
          FutureOr<CalorieGoalProgress?>
        >
    with
        $FutureModifier<CalorieGoalProgress?>,
        $FutureProvider<CalorieGoalProgress?> {
  /// Weight and learned TDEE of the goal that is active on [endDate], from its
  /// start up to [endDate]. `null` without a goal on [endDate].
  CalorieGoalProgressProvider._({
    required CalorieGoalProgressFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calorieGoalProgressProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calorieGoalProgressHash();

  @override
  String toString() {
    return r'calorieGoalProgressProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CalorieGoalProgress?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieGoalProgress?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return calorieGoalProgress(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CalorieGoalProgressProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calorieGoalProgressHash() =>
    r'4f026ddc6fba277e95f13d48883f5f7b5cfd89c2';

/// Weight and learned TDEE of the goal that is active on [endDate], from its
/// start up to [endDate]. `null` without a goal on [endDate].

final class CalorieGoalProgressFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CalorieGoalProgress?>, DateTime> {
  CalorieGoalProgressFamily._()
    : super(
        retry: null,
        name: r'calorieGoalProgressProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Weight and learned TDEE of the goal that is active on [endDate], from its
  /// start up to [endDate]. `null` without a goal on [endDate].

  CalorieGoalProgressProvider call(DateTime endDate) =>
      CalorieGoalProgressProvider._(argument: endDate, from: this);

  @override
  String toString() => r'calorieGoalProgressProvider';
}
