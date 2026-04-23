// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_health_trend_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie health trend snapshot.

@ProviderFor(calorieHealthTrendSnapshot)
final calorieHealthTrendSnapshotProvider =
    CalorieHealthTrendSnapshotProvider._();

/// Calorie health trend snapshot.

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
  /// Calorie health trend snapshot.
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
    r'e733763e7fdbc0fd7952313598637992682a6308';
