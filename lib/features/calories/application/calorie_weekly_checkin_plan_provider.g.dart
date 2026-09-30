// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_weekly_checkin_plan_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The plan of the pending weekly check-in, or `null` without one.

@ProviderFor(calorieWeeklyCheckInPlan)
final calorieWeeklyCheckInPlanProvider = CalorieWeeklyCheckInPlanProvider._();

/// The plan of the pending weekly check-in, or `null` without one.

final class CalorieWeeklyCheckInPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeeklyCheckInPlan?>,
          CalorieWeeklyCheckInPlan?,
          FutureOr<CalorieWeeklyCheckInPlan?>
        >
    with
        $FutureModifier<CalorieWeeklyCheckInPlan?>,
        $FutureProvider<CalorieWeeklyCheckInPlan?> {
  /// The plan of the pending weekly check-in, or `null` without one.
  CalorieWeeklyCheckInPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieWeeklyCheckInPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieWeeklyCheckInPlanHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeeklyCheckInPlan?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeeklyCheckInPlan?> create(Ref ref) {
    return calorieWeeklyCheckInPlan(ref);
  }
}

String _$calorieWeeklyCheckInPlanHash() =>
    r'c60576dd836155985c5809f82dc4218b9735a215';

/// The plan of the latest completed window, for the debug preview.

@ProviderFor(calorieWeeklyCheckInPreviewPlan)
final calorieWeeklyCheckInPreviewPlanProvider =
    CalorieWeeklyCheckInPreviewPlanProvider._();

/// The plan of the latest completed window, for the debug preview.

final class CalorieWeeklyCheckInPreviewPlanProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeeklyCheckInPlan?>,
          CalorieWeeklyCheckInPlan?,
          FutureOr<CalorieWeeklyCheckInPlan?>
        >
    with
        $FutureModifier<CalorieWeeklyCheckInPlan?>,
        $FutureProvider<CalorieWeeklyCheckInPlan?> {
  /// The plan of the latest completed window, for the debug preview.
  CalorieWeeklyCheckInPreviewPlanProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieWeeklyCheckInPreviewPlanProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieWeeklyCheckInPreviewPlanHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeeklyCheckInPlan?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeeklyCheckInPlan?> create(Ref ref) {
    return calorieWeeklyCheckInPreviewPlan(ref);
  }
}

String _$calorieWeeklyCheckInPreviewPlanHash() =>
    r'cb6267d6634486e2560b1fe0360e03bdc5222251';
