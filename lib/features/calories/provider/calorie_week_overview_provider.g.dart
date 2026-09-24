// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_week_overview_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie week overview.

@ProviderFor(calorieWeekOverview)
final calorieWeekOverviewProvider = CalorieWeekOverviewProvider._();

/// Calorie week overview.

final class CalorieWeekOverviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeekOverview>,
          CalorieWeekOverview,
          FutureOr<CalorieWeekOverview>
        >
    with
        $FutureModifier<CalorieWeekOverview>,
        $FutureProvider<CalorieWeekOverview> {
  /// Calorie week overview.
  CalorieWeekOverviewProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieWeekOverviewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieWeekOverviewHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeekOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeekOverview> create(Ref ref) {
    return calorieWeekOverview(ref);
  }
}

String _$calorieWeekOverviewHash() =>
    r'b225b1492e2e058c035ea73a9ae7890fbe23693d';

/// Calorie week overview for window.

@ProviderFor(calorieWeekOverviewForWindow)
final calorieWeekOverviewForWindowProvider =
    CalorieWeekOverviewForWindowFamily._();

/// Calorie week overview for window.

final class CalorieWeekOverviewForWindowProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeekOverview>,
          CalorieWeekOverview,
          FutureOr<CalorieWeekOverview>
        >
    with
        $FutureModifier<CalorieWeekOverview>,
        $FutureProvider<CalorieWeekOverview> {
  /// Calorie week overview for window.
  CalorieWeekOverviewForWindowProvider._({
    required CalorieWeekOverviewForWindowFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calorieWeekOverviewForWindowProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calorieWeekOverviewForWindowHash();

  @override
  String toString() {
    return r'calorieWeekOverviewForWindowProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CalorieWeekOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeekOverview> create(Ref ref) {
    final argument = this.argument as DateTime;
    return calorieWeekOverviewForWindow(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CalorieWeekOverviewForWindowProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calorieWeekOverviewForWindowHash() =>
    r'ae990cef3dfedc76d738ca42719d9028c93bc48f';

/// Calorie week overview for window.

final class CalorieWeekOverviewForWindowFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CalorieWeekOverview>, DateTime> {
  CalorieWeekOverviewForWindowFamily._()
    : super(
        retry: null,
        name: r'calorieWeekOverviewForWindowProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Calorie week overview for window.

  CalorieWeekOverviewForWindowProvider call(DateTime visibleWindowEnd) =>
      CalorieWeekOverviewForWindowProvider._(
        argument: visibleWindowEnd,
        from: this,
      );

  @override
  String toString() => r'calorieWeekOverviewForWindowProvider';
}

/// Calorie week day overview for date.

@ProviderFor(calorieWeekDayOverviewForDate)
final calorieWeekDayOverviewForDateProvider =
    CalorieWeekDayOverviewForDateFamily._();

/// Calorie week day overview for date.

final class CalorieWeekDayOverviewForDateProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeekDayOverview>,
          CalorieWeekDayOverview,
          FutureOr<CalorieWeekDayOverview>
        >
    with
        $FutureModifier<CalorieWeekDayOverview>,
        $FutureProvider<CalorieWeekDayOverview> {
  /// Calorie week day overview for date.
  CalorieWeekDayOverviewForDateProvider._({
    required CalorieWeekDayOverviewForDateFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calorieWeekDayOverviewForDateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calorieWeekDayOverviewForDateHash();

  @override
  String toString() {
    return r'calorieWeekDayOverviewForDateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CalorieWeekDayOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeekDayOverview> create(Ref ref) {
    final argument = this.argument as DateTime;
    return calorieWeekDayOverviewForDate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CalorieWeekDayOverviewForDateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calorieWeekDayOverviewForDateHash() =>
    r'72554858a56ba07d4805f3b866e5bde3072035fe';

/// Calorie week day overview for date.

final class CalorieWeekDayOverviewForDateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CalorieWeekDayOverview>, DateTime> {
  CalorieWeekDayOverviewForDateFamily._()
    : super(
        retry: null,
        name: r'calorieWeekDayOverviewForDateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Calorie week day overview for date.

  CalorieWeekDayOverviewForDateProvider call(DateTime day) =>
      CalorieWeekDayOverviewForDateProvider._(argument: day, from: this);

  @override
  String toString() => r'calorieWeekDayOverviewForDateProvider';
}
