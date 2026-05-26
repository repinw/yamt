// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_learned_tdee_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Resolve optional learned TDEE overrides for multiple days.

@ProviderFor(dailyLearnedTdeeGoalsForDays)
final dailyLearnedTdeeGoalsForDaysProvider =
    DailyLearnedTdeeGoalsForDaysFamily._();

/// Resolve optional learned TDEE overrides for multiple days.

final class DailyLearnedTdeeGoalsForDaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, DailyLearnedTdeeGoalData?>>,
          Map<String, DailyLearnedTdeeGoalData?>,
          FutureOr<Map<String, DailyLearnedTdeeGoalData?>>
        >
    with
        $FutureModifier<Map<String, DailyLearnedTdeeGoalData?>>,
        $FutureProvider<Map<String, DailyLearnedTdeeGoalData?>> {
  /// Resolve optional learned TDEE overrides for multiple days.
  DailyLearnedTdeeGoalsForDaysProvider._({
    required DailyLearnedTdeeGoalsForDaysFamily super.from,
    required DailyLearnedTdeeGoalDaysRequest super.argument,
  }) : super(
         retry: null,
         name: r'dailyLearnedTdeeGoalsForDaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyLearnedTdeeGoalsForDaysHash();

  @override
  String toString() {
    return r'dailyLearnedTdeeGoalsForDaysProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, DailyLearnedTdeeGoalData?>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, DailyLearnedTdeeGoalData?>> create(Ref ref) {
    final argument = this.argument as DailyLearnedTdeeGoalDaysRequest;
    return dailyLearnedTdeeGoalsForDays(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyLearnedTdeeGoalsForDaysProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyLearnedTdeeGoalsForDaysHash() =>
    r'ad6f54ce26b307001201ca3223f9b1233a5fe0b2';

/// Resolve optional learned TDEE overrides for multiple days.

final class DailyLearnedTdeeGoalsForDaysFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, DailyLearnedTdeeGoalData?>>,
          DailyLearnedTdeeGoalDaysRequest
        > {
  DailyLearnedTdeeGoalsForDaysFamily._()
    : super(
        retry: null,
        name: r'dailyLearnedTdeeGoalsForDaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolve optional learned TDEE overrides for multiple days.

  DailyLearnedTdeeGoalsForDaysProvider call(
    DailyLearnedTdeeGoalDaysRequest request,
  ) => DailyLearnedTdeeGoalsForDaysProvider._(argument: request, from: this);

  @override
  String toString() => r'dailyLearnedTdeeGoalsForDaysProvider';
}

/// Resolve optional learned TDEE override for [day].

@ProviderFor(dailyLearnedTdeeGoalForDay)
final dailyLearnedTdeeGoalForDayProvider = DailyLearnedTdeeGoalForDayFamily._();

/// Resolve optional learned TDEE override for [day].

final class DailyLearnedTdeeGoalForDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyLearnedTdeeGoalData?>,
          DailyLearnedTdeeGoalData?,
          FutureOr<DailyLearnedTdeeGoalData?>
        >
    with
        $FutureModifier<DailyLearnedTdeeGoalData?>,
        $FutureProvider<DailyLearnedTdeeGoalData?> {
  /// Resolve optional learned TDEE override for [day].
  DailyLearnedTdeeGoalForDayProvider._({
    required DailyLearnedTdeeGoalForDayFamily super.from,
    required ({DateTime day, DateTime today, double storedGoalKcal})
    super.argument,
  }) : super(
         retry: null,
         name: r'dailyLearnedTdeeGoalForDayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyLearnedTdeeGoalForDayHash();

  @override
  String toString() {
    return r'dailyLearnedTdeeGoalForDayProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DailyLearnedTdeeGoalData?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DailyLearnedTdeeGoalData?> create(Ref ref) {
    final argument =
        this.argument
            as ({DateTime day, DateTime today, double storedGoalKcal});
    return dailyLearnedTdeeGoalForDay(
      ref,
      day: argument.day,
      today: argument.today,
      storedGoalKcal: argument.storedGoalKcal,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DailyLearnedTdeeGoalForDayProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyLearnedTdeeGoalForDayHash() =>
    r'940fc07b202c2a8e5fb285f4f1d9aeb3e1944878';

/// Resolve optional learned TDEE override for [day].

final class DailyLearnedTdeeGoalForDayFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DailyLearnedTdeeGoalData?>,
          ({DateTime day, DateTime today, double storedGoalKcal})
        > {
  DailyLearnedTdeeGoalForDayFamily._()
    : super(
        retry: null,
        name: r'dailyLearnedTdeeGoalForDayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Resolve optional learned TDEE override for [day].

  DailyLearnedTdeeGoalForDayProvider call({
    required DateTime day,
    required DateTime today,
    required double storedGoalKcal,
  }) => DailyLearnedTdeeGoalForDayProvider._(
    argument: (day: day, today: today, storedGoalKcal: storedGoalKcal),
    from: this,
  );

  @override
  String toString() => r'dailyLearnedTdeeGoalForDayProvider';
}
