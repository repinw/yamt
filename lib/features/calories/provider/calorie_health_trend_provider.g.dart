// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_health_trend_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(calorieHealthTrendSnapshot)
final calorieHealthTrendSnapshotProvider =
    CalorieHealthTrendSnapshotProvider._();

final class CalorieHealthTrendSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieHealthTrendSnapshot>,
          CalorieHealthTrendSnapshot,
          FutureOr<CalorieHealthTrendSnapshot>
        >
    with
        $FutureModifier<CalorieHealthTrendSnapshot>,
        $FutureProvider<CalorieHealthTrendSnapshot> {
  CalorieHealthTrendSnapshotProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieHealthTrendSnapshotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieHealthTrendSnapshotHash();

  @$internal
  @override
  $FutureProviderElement<CalorieHealthTrendSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieHealthTrendSnapshot> create(Ref ref) {
    return calorieHealthTrendSnapshot(ref);
  }
}

String _$calorieHealthTrendSnapshotHash() =>
    r'5e6c00f55c9045e95f50affb14ede8d617479d49';
