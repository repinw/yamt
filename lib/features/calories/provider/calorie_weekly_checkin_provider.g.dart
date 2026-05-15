// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_weekly_checkin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie weekly check in view model.

@ProviderFor(calorieWeeklyCheckInViewModel)
final calorieWeeklyCheckInViewModelProvider =
    CalorieWeeklyCheckInViewModelProvider._();

/// Calorie weekly check in view model.

final class CalorieWeeklyCheckInViewModelProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeeklyCheckInViewModel>,
          CalorieWeeklyCheckInViewModel,
          FutureOr<CalorieWeeklyCheckInViewModel>
        >
    with
        $FutureModifier<CalorieWeeklyCheckInViewModel>,
        $FutureProvider<CalorieWeeklyCheckInViewModel> {
  /// Calorie weekly check in view model.
  CalorieWeeklyCheckInViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieWeeklyCheckInViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieWeeklyCheckInViewModelHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeeklyCheckInViewModel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeeklyCheckInViewModel> create(Ref ref) {
    return calorieWeeklyCheckInViewModel(ref);
  }
}

String _$calorieWeeklyCheckInViewModelHash() =>
    r'3cc89414c38fdce8969cbeadf3ad3dd53f3f9f11';

/// Calorie weekly check-in data.

@ProviderFor(calorieWeeklyCheckInData)
final calorieWeeklyCheckInDataProvider = CalorieWeeklyCheckInDataProvider._();

/// Calorie weekly check-in data.

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
  /// Calorie weekly check-in data.
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
    r'054e3e8502eb11fc6ec62e15379d66555f438279';
