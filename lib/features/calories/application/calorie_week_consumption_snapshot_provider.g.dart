// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_week_consumption_snapshot_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Calorie week consumption snapshot.

@ProviderFor(calorieWeekConsumptionSnapshot)
final calorieWeekConsumptionSnapshotProvider =
    CalorieWeekConsumptionSnapshotProvider._();

/// Calorie week consumption snapshot.

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
  /// Calorie week consumption snapshot.
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
    r'6ba6dba802963acc759a066f0ff4c016c118d2a9';

/// Calorie week consumption snapshot for window.

@ProviderFor(calorieWeekConsumptionSnapshotForWindow)
final calorieWeekConsumptionSnapshotForWindowProvider =
    CalorieWeekConsumptionSnapshotForWindowFamily._();

/// Calorie week consumption snapshot for window.

final class CalorieWeekConsumptionSnapshotForWindowProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeekConsumptionSnapshot>,
          CalorieWeekConsumptionSnapshot,
          FutureOr<CalorieWeekConsumptionSnapshot>
        >
    with
        $FutureModifier<CalorieWeekConsumptionSnapshot>,
        $FutureProvider<CalorieWeekConsumptionSnapshot> {
  /// Calorie week consumption snapshot for window.
  CalorieWeekConsumptionSnapshotForWindowProvider._({
    required CalorieWeekConsumptionSnapshotForWindowFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calorieWeekConsumptionSnapshotForWindowProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$calorieWeekConsumptionSnapshotForWindowHash();

  @override
  String toString() {
    return r'calorieWeekConsumptionSnapshotForWindowProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CalorieWeekConsumptionSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeekConsumptionSnapshot> create(Ref ref) {
    final argument = this.argument as DateTime;
    return calorieWeekConsumptionSnapshotForWindow(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CalorieWeekConsumptionSnapshotForWindowProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calorieWeekConsumptionSnapshotForWindowHash() =>
    r'42c6d2e532b5a55fa779862c72a32753fd806e44';

/// Calorie week consumption snapshot for window.

final class CalorieWeekConsumptionSnapshotForWindowFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CalorieWeekConsumptionSnapshot>,
          DateTime
        > {
  CalorieWeekConsumptionSnapshotForWindowFamily._()
    : super(
        retry: null,
        name: r'calorieWeekConsumptionSnapshotForWindowProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Calorie week consumption snapshot for window.

  CalorieWeekConsumptionSnapshotForWindowProvider call(
    DateTime visibleWindowEnd,
  ) => CalorieWeekConsumptionSnapshotForWindowProvider._(
    argument: visibleWindowEnd,
    from: this,
  );

  @override
  String toString() => r'calorieWeekConsumptionSnapshotForWindowProvider';
}
