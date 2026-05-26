// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_weekly_checkin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie goal settings consumed by diary UI.

@ProviderFor(diaryCalorieGoalSettings)
final diaryCalorieGoalSettingsProvider = DiaryCalorieGoalSettingsProvider._();

/// Calorie goal settings consumed by diary UI.

final class DiaryCalorieGoalSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieGoalSettings>,
          CalorieGoalSettings,
          FutureOr<CalorieGoalSettings>
        >
    with
        $FutureModifier<CalorieGoalSettings>,
        $FutureProvider<CalorieGoalSettings> {
  /// Calorie goal settings consumed by diary UI.
  DiaryCalorieGoalSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryCalorieGoalSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryCalorieGoalSettingsHash();

  @$internal
  @override
  $FutureProviderElement<CalorieGoalSettings> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieGoalSettings> create(Ref ref) {
    return diaryCalorieGoalSettings(ref);
  }
}

String _$diaryCalorieGoalSettingsHash() =>
    r'856d13ab89212052dcdaf2fb71e1c650f8666400';

/// Weekly check-in data consumed by diary UI.

@ProviderFor(diaryWeeklyCheckInData)
final diaryWeeklyCheckInDataProvider = DiaryWeeklyCheckInDataProvider._();

/// Weekly check-in data consumed by diary UI.

final class DiaryWeeklyCheckInDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryWeeklyCheckInData>,
          DiaryWeeklyCheckInData,
          FutureOr<DiaryWeeklyCheckInData>
        >
    with
        $FutureModifier<DiaryWeeklyCheckInData>,
        $FutureProvider<DiaryWeeklyCheckInData> {
  /// Weekly check-in data consumed by diary UI.
  DiaryWeeklyCheckInDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryWeeklyCheckInDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryWeeklyCheckInDataHash();

  @$internal
  @override
  $FutureProviderElement<DiaryWeeklyCheckInData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryWeeklyCheckInData> create(Ref ref) {
    return diaryWeeklyCheckInData(ref);
  }
}

String _$diaryWeeklyCheckInDataHash() =>
    r'2575f93ab69a8f0f903d7ec33c551883f7dbc0b7';

/// Whether [selectedDay] currently has calorie entries in the weekly window.

@ProviderFor(diaryWeeklyCheckInSelectedDayHasEntries)
final diaryWeeklyCheckInSelectedDayHasEntriesProvider =
    DiaryWeeklyCheckInSelectedDayHasEntriesFamily._();

/// Whether [selectedDay] currently has calorie entries in the weekly window.

final class DiaryWeeklyCheckInSelectedDayHasEntriesProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether [selectedDay] currently has calorie entries in the weekly window.
  DiaryWeeklyCheckInSelectedDayHasEntriesProvider._({
    required DiaryWeeklyCheckInSelectedDayHasEntriesFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryWeeklyCheckInSelectedDayHasEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$diaryWeeklyCheckInSelectedDayHasEntriesHash();

  @override
  String toString() {
    return r'diaryWeeklyCheckInSelectedDayHasEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryWeeklyCheckInSelectedDayHasEntries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryWeeklyCheckInSelectedDayHasEntriesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryWeeklyCheckInSelectedDayHasEntriesHash() =>
    r'ad8e2783b093454eda5fdcd7e606b500679addcc';

/// Whether [selectedDay] currently has calorie entries in the weekly window.

final class DiaryWeeklyCheckInSelectedDayHasEntriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, DateTime> {
  DiaryWeeklyCheckInSelectedDayHasEntriesFamily._()
    : super(
        retry: null,
        name: r'diaryWeeklyCheckInSelectedDayHasEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [selectedDay] currently has calorie entries in the weekly window.

  DiaryWeeklyCheckInSelectedDayHasEntriesProvider call(DateTime selectedDay) =>
      DiaryWeeklyCheckInSelectedDayHasEntriesProvider._(
        argument: selectedDay,
        from: this,
      );

  @override
  String toString() => r'diaryWeeklyCheckInSelectedDayHasEntriesProvider';
}

/// Weekly check-in actions needed by diary presentation widgets.

@ProviderFor(diaryWeeklyCheckInActions)
final diaryWeeklyCheckInActionsProvider = DiaryWeeklyCheckInActionsProvider._();

/// Weekly check-in actions needed by diary presentation widgets.

final class DiaryWeeklyCheckInActionsProvider
    extends
        $FunctionalProvider<
          DiaryWeeklyCheckInActions,
          DiaryWeeklyCheckInActions,
          DiaryWeeklyCheckInActions
        >
    with $Provider<DiaryWeeklyCheckInActions> {
  /// Weekly check-in actions needed by diary presentation widgets.
  DiaryWeeklyCheckInActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryWeeklyCheckInActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryWeeklyCheckInActionsHash();

  @$internal
  @override
  $ProviderElement<DiaryWeeklyCheckInActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryWeeklyCheckInActions create(Ref ref) {
    return diaryWeeklyCheckInActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryWeeklyCheckInActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryWeeklyCheckInActions>(value),
    );
  }
}

String _$diaryWeeklyCheckInActionsHash() =>
    r'2bfef4c918138abe8f75bb8cab388b38a90a301a';
