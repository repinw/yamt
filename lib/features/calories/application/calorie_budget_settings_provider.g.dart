// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_budget_settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The goal settings that budgets read.
///
/// The stored settings, whose goals follow the daily TDEE once it is
/// computed; until then the stored goals stand, so a budget never waits.

@ProviderFor(calorieBudgetSettings)
final calorieBudgetSettingsProvider = CalorieBudgetSettingsProvider._();

/// The goal settings that budgets read.
///
/// The stored settings, whose goals follow the daily TDEE once it is
/// computed; until then the stored goals stand, so a budget never waits.

final class CalorieBudgetSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieGoalSettings>,
          CalorieGoalSettings,
          FutureOr<CalorieGoalSettings>
        >
    with
        $FutureModifier<CalorieGoalSettings>,
        $FutureProvider<CalorieGoalSettings> {
  /// The goal settings that budgets read.
  ///
  /// The stored settings, whose goals follow the daily TDEE once it is
  /// computed; until then the stored goals stand, so a budget never waits.
  CalorieBudgetSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieBudgetSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieBudgetSettingsHash();

  @$internal
  @override
  $FutureProviderElement<CalorieGoalSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieGoalSettings> create(Ref ref) {
    return calorieBudgetSettings(ref);
  }
}

String _$calorieBudgetSettingsHash() =>
    r'ae5300f23c1d6b6aaee0f1317863b2cfda59bd6c';

/// How far each goal moves with the daily TDEE, through the running week.

@ProviderFor(goalTdeeOffsetsByDay)
final goalTdeeOffsetsByDayProvider = GoalTdeeOffsetsByDayProvider._();

/// How far each goal moves with the daily TDEE, through the running week.

final class GoalTdeeOffsetsByDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<GoalTdeeOffsets>,
          GoalTdeeOffsets,
          FutureOr<GoalTdeeOffsets>
        >
    with $FutureModifier<GoalTdeeOffsets>, $FutureProvider<GoalTdeeOffsets> {
  /// How far each goal moves with the daily TDEE, through the running week.
  GoalTdeeOffsetsByDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalTdeeOffsetsByDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalTdeeOffsetsByDayHash();

  @$internal
  @override
  $FutureProviderElement<GoalTdeeOffsets> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GoalTdeeOffsets> create(Ref ref) {
    return goalTdeeOffsetsByDay(ref);
  }
}

String _$goalTdeeOffsetsByDayHash() =>
    r'09cb0897df51b30ddb02618c91da82cc32e38072';

/// The diary entries from [startDay] on, from the local cache first.

@ProviderFor(calorieEntriesFrom)
final calorieEntriesFromProvider = CalorieEntriesFromFamily._();

/// The diary entries from [startDay] on, from the local cache first.

final class CalorieEntriesFromProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CalorieEntry>>,
          List<CalorieEntry>,
          Stream<List<CalorieEntry>>
        >
    with
        $FutureModifier<List<CalorieEntry>>,
        $StreamProvider<List<CalorieEntry>> {
  /// The diary entries from [startDay] on, from the local cache first.
  CalorieEntriesFromProvider._({
    required CalorieEntriesFromFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calorieEntriesFromProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calorieEntriesFromHash();

  @override
  String toString() {
    return r'calorieEntriesFromProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CalorieEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CalorieEntry>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return calorieEntriesFrom(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CalorieEntriesFromProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calorieEntriesFromHash() =>
    r'ed3fc49e26712122f60ba6f61c4d6e5f7aa80d02';

/// The diary entries from [startDay] on, from the local cache first.

final class CalorieEntriesFromFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<CalorieEntry>>, DateTime> {
  CalorieEntriesFromFamily._()
    : super(
        retry: null,
        name: r'calorieEntriesFromProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The diary entries from [startDay] on, from the local cache first.

  CalorieEntriesFromProvider call(DateTime startDay) =>
      CalorieEntriesFromProvider._(argument: startDay, from: this);

  @override
  String toString() => r'calorieEntriesFromProvider';
}

/// Health weights from before [startDay] on, loaded once, so an entry
/// change only recomputes.
///
/// shortcut: a weight synced later in the day counts from the next day on;
/// reload on a Health change event when one exists.

@ProviderFor(healthWeightSamplesFrom)
final healthWeightSamplesFromProvider = HealthWeightSamplesFromFamily._();

/// Health weights from before [startDay] on, loaded once, so an entry
/// change only recomputes.
///
/// shortcut: a weight synced later in the day counts from the next day on;
/// reload on a Health change event when one exists.

final class HealthWeightSamplesFromProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<HealthWeightSample>>,
          List<HealthWeightSample>,
          FutureOr<List<HealthWeightSample>>
        >
    with
        $FutureModifier<List<HealthWeightSample>>,
        $FutureProvider<List<HealthWeightSample>> {
  /// Health weights from before [startDay] on, loaded once, so an entry
  /// change only recomputes.
  ///
  /// shortcut: a weight synced later in the day counts from the next day on;
  /// reload on a Health change event when one exists.
  HealthWeightSamplesFromProvider._({
    required HealthWeightSamplesFromFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'healthWeightSamplesFromProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$healthWeightSamplesFromHash();

  @override
  String toString() {
    return r'healthWeightSamplesFromProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<HealthWeightSample>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<HealthWeightSample>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return healthWeightSamplesFrom(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HealthWeightSamplesFromProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$healthWeightSamplesFromHash() =>
    r'176fe03226c3246910580c9506e7e7cc74046e6e';

/// Health weights from before [startDay] on, loaded once, so an entry
/// change only recomputes.
///
/// shortcut: a weight synced later in the day counts from the next day on;
/// reload on a Health change event when one exists.

final class HealthWeightSamplesFromFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<HealthWeightSample>>,
          DateTime
        > {
  HealthWeightSamplesFromFamily._()
    : super(
        retry: null,
        name: r'healthWeightSamplesFromProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Health weights from before [startDay] on, loaded once, so an entry
  /// change only recomputes.
  ///
  /// shortcut: a weight synced later in the day counts from the next day on;
  /// reload on a Health change event when one exists.

  HealthWeightSamplesFromProvider call(DateTime startDay) =>
      HealthWeightSamplesFromProvider._(argument: startDay, from: this);

  @override
  String toString() => r'healthWeightSamplesFromProvider';
}
