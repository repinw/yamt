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
