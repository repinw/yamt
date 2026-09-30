// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_weekly_checkin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie weekly check in data.

@ProviderFor(calorieWeeklyCheckInData)
final calorieWeeklyCheckInDataProvider = CalorieWeeklyCheckInDataProvider._();

/// Calorie weekly check in data.

final class CalorieWeeklyCheckInDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeeklyCheckInData>,
          CalorieWeeklyCheckInData,
          FutureOr<CalorieWeeklyCheckInData>
        >
    with
        $FutureModifier<CalorieWeeklyCheckInData>,
        $FutureProvider<CalorieWeeklyCheckInData> {
  /// Calorie weekly check in data.
  CalorieWeeklyCheckInDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieWeeklyCheckInDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieWeeklyCheckInDataHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeeklyCheckInData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeeklyCheckInData> create(Ref ref) {
    return calorieWeeklyCheckInData(ref);
  }
}

String _$calorieWeeklyCheckInDataHash() =>
    r'e874ab368aa62e56c0277b54a33880bc4f006bdd';

/// Weekly check-in data of the latest completed window, decided or not, or
/// demo data when the goal has no completed window yet.
///
/// Only for the debug preview of the check-in sheet.

@ProviderFor(calorieWeeklyCheckInPreviewData)
final calorieWeeklyCheckInPreviewDataProvider =
    CalorieWeeklyCheckInPreviewDataProvider._();

/// Weekly check-in data of the latest completed window, decided or not, or
/// demo data when the goal has no completed window yet.
///
/// Only for the debug preview of the check-in sheet.

final class CalorieWeeklyCheckInPreviewDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeeklyCheckInData>,
          CalorieWeeklyCheckInData,
          FutureOr<CalorieWeeklyCheckInData>
        >
    with
        $FutureModifier<CalorieWeeklyCheckInData>,
        $FutureProvider<CalorieWeeklyCheckInData> {
  /// Weekly check-in data of the latest completed window, decided or not, or
  /// demo data when the goal has no completed window yet.
  ///
  /// Only for the debug preview of the check-in sheet.
  CalorieWeeklyCheckInPreviewDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieWeeklyCheckInPreviewDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieWeeklyCheckInPreviewDataHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeeklyCheckInData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeeklyCheckInData> create(Ref ref) {
    return calorieWeeklyCheckInPreviewData(ref);
  }
}

String _$calorieWeeklyCheckInPreviewDataHash() =>
    r'104808d671ac8eec152405d89f8281e711b79c60';
