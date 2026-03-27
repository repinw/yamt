// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_week_overview_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieWeekOverview)
final calorieWeekOverviewProvider = CalorieWeekOverviewProvider._();

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
    r'74148f22c5b4bfdb8ba766d97853a122a437894e';
