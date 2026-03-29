// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_week_overview_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieWeekConsumptionSnapshot)
final calorieWeekConsumptionSnapshotProvider =
    CalorieWeekConsumptionSnapshotProvider._();

final class CalorieWeekConsumptionSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeekConsumptionSnapshot>,
          CalorieWeekConsumptionSnapshot,
          FutureOr<CalorieWeekConsumptionSnapshot>
        >
    with
        $FutureModifier<CalorieWeekConsumptionSnapshot>,
        $FutureProvider<CalorieWeekConsumptionSnapshot> {
  CalorieWeekConsumptionSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieWeekConsumptionSnapshotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieWeekConsumptionSnapshotHash();

  @$internal
  @override
  $FutureProviderElement<CalorieWeekConsumptionSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeekConsumptionSnapshot> create(Ref ref) {
    return calorieWeekConsumptionSnapshot(ref);
  }
}

String _$calorieWeekConsumptionSnapshotHash() =>
    r'e635bb61b0bfdb2a31f21d6a2ef96ff01f886e95';

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
    r'0dcf2721c81f1a6e9f701670df06920b05aa4900';
