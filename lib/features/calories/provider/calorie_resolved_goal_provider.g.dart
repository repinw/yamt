// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_resolved_goal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolved calorie goal for day.

@ProviderFor(resolvedCalorieGoalForDay)
final resolvedCalorieGoalForDayProvider = ResolvedCalorieGoalForDayFamily._();

/// Resolved calorie goal for day.

final class ResolvedCalorieGoalForDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<ResolvedCalorieGoalData>,
          ResolvedCalorieGoalData,
          FutureOr<ResolvedCalorieGoalData>
        >
    with
        $FutureModifier<ResolvedCalorieGoalData>,
        $FutureProvider<ResolvedCalorieGoalData> {
  /// Resolved calorie goal for day.
  ResolvedCalorieGoalForDayProvider._({
    required ResolvedCalorieGoalForDayFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'resolvedCalorieGoalForDayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resolvedCalorieGoalForDayHash();

  @override
  String toString() {
    return r'resolvedCalorieGoalForDayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ResolvedCalorieGoalData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ResolvedCalorieGoalData> create(Ref ref) {
    final argument = this.argument as DateTime;
    return resolvedCalorieGoalForDay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ResolvedCalorieGoalForDayProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resolvedCalorieGoalForDayHash() =>
    r'aebce3743e56d9e813bba8b8b2fc131c72f317ef';

/// Resolved calorie goal for day.

final class ResolvedCalorieGoalForDayFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<ResolvedCalorieGoalData>, DateTime> {
  ResolvedCalorieGoalForDayFamily._()
    : super(
        retry: null,
        name: r'resolvedCalorieGoalForDayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolved calorie goal for day.

  ResolvedCalorieGoalForDayProvider call(DateTime day) =>
      ResolvedCalorieGoalForDayProvider._(argument: day, from: this);

  @override
  String toString() => r'resolvedCalorieGoalForDayProvider';
}
