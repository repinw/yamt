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
    r'225ad9383f988e81c885fb47fa5649f146d32b26';
