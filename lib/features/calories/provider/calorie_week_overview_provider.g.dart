// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_week_overview_provider.dart';

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
    r'94debead174ee08ef160f4bef048b07a2810f7de';

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
    r'ceb8e50f957df9ea2c52fd25afc0995625a90724';

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

/// Calorie week overview.

@ProviderFor(calorieWeekOverview)
final calorieWeekOverviewProvider = CalorieWeekOverviewProvider._();

/// Calorie week overview.

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
  /// Calorie week overview.
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
    r'fec207db49ed096beb332cfd22a84252060dc198';

/// Calorie week overview for window.

@ProviderFor(calorieWeekOverviewForWindow)
final calorieWeekOverviewForWindowProvider =
    CalorieWeekOverviewForWindowFamily._();

/// Calorie week overview for window.

final class CalorieWeekOverviewForWindowProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeekOverview>,
          CalorieWeekOverview,
          FutureOr<CalorieWeekOverview>
        >
    with
        $FutureModifier<CalorieWeekOverview>,
        $FutureProvider<CalorieWeekOverview> {
  /// Calorie week overview for window.
  CalorieWeekOverviewForWindowProvider._({
    required CalorieWeekOverviewForWindowFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calorieWeekOverviewForWindowProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calorieWeekOverviewForWindowHash();

  @override
  String toString() {
    return r'calorieWeekOverviewForWindowProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CalorieWeekOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeekOverview> create(Ref ref) {
    final argument = this.argument as DateTime;
    return calorieWeekOverviewForWindow(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CalorieWeekOverviewForWindowProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calorieWeekOverviewForWindowHash() =>
    r'09efc442ba2127cac7b060ba03ff5ea01dd0b578';

/// Calorie week overview for window.

final class CalorieWeekOverviewForWindowFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CalorieWeekOverview>, DateTime> {
  CalorieWeekOverviewForWindowFamily._()
    : super(
        retry: null,
        name: r'calorieWeekOverviewForWindowProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Calorie week overview for window.

  CalorieWeekOverviewForWindowProvider call(DateTime visibleWindowEnd) =>
      CalorieWeekOverviewForWindowProvider._(
        argument: visibleWindowEnd,
        from: this,
      );

  @override
  String toString() => r'calorieWeekOverviewForWindowProvider';
}

/// Calorie week day overview for date.

@ProviderFor(calorieWeekDayOverviewForDate)
final calorieWeekDayOverviewForDateProvider =
    CalorieWeekDayOverviewForDateFamily._();

/// Calorie week day overview for date.

final class CalorieWeekDayOverviewForDateProvider
    extends
        $FunctionalProvider<
          AsyncValue<CalorieWeekDayOverview>,
          CalorieWeekDayOverview,
          FutureOr<CalorieWeekDayOverview>
        >
    with
        $FutureModifier<CalorieWeekDayOverview>,
        $FutureProvider<CalorieWeekDayOverview> {
  /// Calorie week day overview for date.
  CalorieWeekDayOverviewForDateProvider._({
    required CalorieWeekDayOverviewForDateFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'calorieWeekDayOverviewForDateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$calorieWeekDayOverviewForDateHash();

  @override
  String toString() {
    return r'calorieWeekDayOverviewForDateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CalorieWeekDayOverview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CalorieWeekDayOverview> create(Ref ref) {
    final argument = this.argument as DateTime;
    return calorieWeekDayOverviewForDate(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CalorieWeekDayOverviewForDateProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$calorieWeekDayOverviewForDateHash() =>
    r'2d57699f01eb231abe9931b9f6ac723f1082e9e3';

/// Calorie week day overview for date.

final class CalorieWeekDayOverviewForDateFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CalorieWeekDayOverview>, DateTime> {
  CalorieWeekDayOverviewForDateFamily._()
    : super(
        retry: null,
        name: r'calorieWeekDayOverviewForDateProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Calorie week day overview for date.

  CalorieWeekDayOverviewForDateProvider call(DateTime day) =>
      CalorieWeekDayOverviewForDateProvider._(argument: day, from: this);

  @override
  String toString() => r'calorieWeekDayOverviewForDateProvider';
}
