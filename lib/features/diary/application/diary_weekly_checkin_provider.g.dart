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
          AsyncValue<CalorieWeeklyCheckInData>,
          CalorieWeeklyCheckInData,
          FutureOr<CalorieWeeklyCheckInData>
        >
    with
        $FutureModifier<CalorieWeeklyCheckInData>,
        $FutureProvider<CalorieWeeklyCheckInData> {
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
  $FutureProviderElement<CalorieWeeklyCheckInData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeeklyCheckInData> create(Ref ref) {
    return diaryWeeklyCheckInData(ref);
  }
}

String _$diaryWeeklyCheckInDataHash() =>
    r'a5380daf95de3811f7ec1028344aa081bdca99ee';

/// Plan of the pending weekly check-in consumed by diary UI.

@ProviderFor(diaryWeeklyCheckInPlan)
final diaryWeeklyCheckInPlanProvider = DiaryWeeklyCheckInPlanProvider._();

/// Plan of the pending weekly check-in consumed by diary UI.

final class DiaryWeeklyCheckInPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeeklyCheckInPlan?>,
          CalorieWeeklyCheckInPlan?,
          FutureOr<CalorieWeeklyCheckInPlan?>
        >
    with
        $FutureModifier<CalorieWeeklyCheckInPlan?>,
        $FutureProvider<CalorieWeeklyCheckInPlan?> {
  /// Plan of the pending weekly check-in consumed by diary UI.
  DiaryWeeklyCheckInPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryWeeklyCheckInPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryWeeklyCheckInPlanHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeeklyCheckInPlan?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeeklyCheckInPlan?> create(Ref ref) {
    return diaryWeeklyCheckInPlan(ref);
  }
}

String _$diaryWeeklyCheckInPlanHash() =>
    r'3c67ef31cc91a048cf5a879c90aaac835ecaaa08';

/// Plan of the latest completed window, for the debug preview.

@ProviderFor(diaryWeeklyCheckInPreviewPlan)
final diaryWeeklyCheckInPreviewPlanProvider =
    DiaryWeeklyCheckInPreviewPlanProvider._();

/// Plan of the latest completed window, for the debug preview.

final class DiaryWeeklyCheckInPreviewPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeeklyCheckInPlan?>,
          CalorieWeeklyCheckInPlan?,
          FutureOr<CalorieWeeklyCheckInPlan?>
        >
    with
        $FutureModifier<CalorieWeeklyCheckInPlan?>,
        $FutureProvider<CalorieWeeklyCheckInPlan?> {
  /// Plan of the latest completed window, for the debug preview.
  DiaryWeeklyCheckInPreviewPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryWeeklyCheckInPreviewPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryWeeklyCheckInPreviewPlanHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeeklyCheckInPlan?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeeklyCheckInPlan?> create(Ref ref) {
    return diaryWeeklyCheckInPreviewPlan(ref);
  }
}

String _$diaryWeeklyCheckInPreviewPlanHash() =>
    r'3fd31a22fe992bc65e7be408830d97db07800d1a';

/// Check-in data of the latest completed window, for the debug preview.

@ProviderFor(diaryWeeklyCheckInPreviewData)
final diaryWeeklyCheckInPreviewDataProvider =
    DiaryWeeklyCheckInPreviewDataProvider._();

/// Check-in data of the latest completed window, for the debug preview.

final class DiaryWeeklyCheckInPreviewDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeeklyCheckInData>,
          CalorieWeeklyCheckInData,
          FutureOr<CalorieWeeklyCheckInData>
        >
    with
        $FutureModifier<CalorieWeeklyCheckInData>,
        $FutureProvider<CalorieWeeklyCheckInData> {
  /// Check-in data of the latest completed window, for the debug preview.
  DiaryWeeklyCheckInPreviewDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryWeeklyCheckInPreviewDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryWeeklyCheckInPreviewDataHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeeklyCheckInData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeeklyCheckInData> create(Ref ref) {
    return diaryWeeklyCheckInPreviewData(ref);
  }
}

String _$diaryWeeklyCheckInPreviewDataHash() =>
    r'9e72cd0c826292eddc6af7836120fc7e3d812bda';

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
    r'd6861b50019f20ea6fb877dc6b1153514bb78b76';
