// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_resolved_goal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolved calorie goals keyed by diary day key.

@ProviderFor(resolvedCalorieGoalsForDays)
final resolvedCalorieGoalsForDaysProvider =
    ResolvedCalorieGoalsForDaysFamily._();

/// Resolved calorie goals keyed by diary day key.

final class ResolvedCalorieGoalsForDaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, ResolvedCalorieGoalData>>,
          Map<String, ResolvedCalorieGoalData>,
          FutureOr<Map<String, ResolvedCalorieGoalData>>
        >
    with
        $FutureModifier<Map<String, ResolvedCalorieGoalData>>,
        $FutureProvider<Map<String, ResolvedCalorieGoalData>> {
  /// Resolved calorie goals keyed by diary day key.
  ResolvedCalorieGoalsForDaysProvider._({
    required ResolvedCalorieGoalsForDaysFamily super.from,
    required ResolvedCalorieGoalDaysRequest super.argument,
  }) : super(
         retry: null,
         name: r'resolvedCalorieGoalsForDaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$resolvedCalorieGoalsForDaysHash();

  @override
  String toString() {
    return r'resolvedCalorieGoalsForDaysProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, ResolvedCalorieGoalData>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, ResolvedCalorieGoalData>> create(Ref ref) {
    final argument = this.argument as ResolvedCalorieGoalDaysRequest;
    return resolvedCalorieGoalsForDays(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ResolvedCalorieGoalsForDaysProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$resolvedCalorieGoalsForDaysHash() =>
    r'4c63cfb3d0dec5420fe564fd6a9d403398bb47b1';

/// Resolved calorie goals keyed by diary day key.

final class ResolvedCalorieGoalsForDaysFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, ResolvedCalorieGoalData>>,
          ResolvedCalorieGoalDaysRequest
        > {
  ResolvedCalorieGoalsForDaysFamily._()
    : super(
        retry: null,
        name: r'resolvedCalorieGoalsForDaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolved calorie goals keyed by diary day key.

  ResolvedCalorieGoalsForDaysProvider call(
    ResolvedCalorieGoalDaysRequest request,
  ) => ResolvedCalorieGoalsForDaysProvider._(argument: request, from: this);

  @override
  String toString() => r'resolvedCalorieGoalsForDaysProvider';
}

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
    r'920f65fe3959a566eefa6ac8df8eda32517631aa';

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
