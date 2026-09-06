// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_week_overview_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalorieWeekDayOverview _$CalorieWeekDayOverviewFromJson(
  Map<String, dynamic> json,
) => CalorieWeekDayOverview(
  date: DateTime.parse(json['date'] as String),
  totalKcal: (json['total_kcal'] as num).toDouble(),
  goalKcal: (json['goal_kcal'] as num).toDouble(),
  entryCount: (json['entry_count'] as num).toInt(),
  baseGoalKcal: (json['base_goal_kcal'] as num?)?.toDouble(),
  activityBonusKcal: (json['activity_bonus_kcal'] as num?)?.toDouble() ?? 0,
  todayActiveKcal: (json['today_active_kcal'] as num?)?.toInt() ?? 0,
  expectedActivityKcal:
      (json['expected_activity_kcal'] as num?)?.toDouble() ?? 0,
  isActivityTrackingActive:
      json['is_activity_tracking_active'] as bool? ?? false,
  isHeartDay: json['is_heart_day'] as bool? ?? false,
);

Map<String, dynamic> _$CalorieWeekDayOverviewToJson(
  CalorieWeekDayOverview instance,
) => <String, dynamic>{
  'date': instance.date.toIso8601String(),
  'total_kcal': instance.totalKcal,
  'goal_kcal': instance.goalKcal,
  'base_goal_kcal': instance.baseGoalKcal,
  'activity_bonus_kcal': instance.activityBonusKcal,
  'today_active_kcal': instance.todayActiveKcal,
  'expected_activity_kcal': instance.expectedActivityKcal,
  'is_activity_tracking_active': instance.isActivityTrackingActive,
  'entry_count': instance.entryCount,
  'is_heart_day': instance.isHeartDay,
};

CalorieWeekOverview _$CalorieWeekOverviewFromJson(
  Map<String, dynamic> json,
) => CalorieWeekOverview(
  days: (json['days'] as List<dynamic>)
      .map((e) => CalorieWeekDayOverview.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalConsumedKcal: (json['total_consumed_kcal'] as num).toDouble(),
  totalGoalKcal: (json['total_goal_kcal'] as num).toDouble(),
  remainingKcal: (json['remaining_kcal'] as num).toDouble(),
  balanceStartDate: DateTime.parse(json['balance_start_date'] as String),
  carryoverBeforeTodayKcal: (json['carryover_before_today_kcal'] as num)
      .toDouble(),
  todayFlexibleGoalKcal: (json['today_flexible_goal_kcal'] as num).toDouble(),
  goalStartsInFuture: json['goal_starts_in_future'] as bool,
  nextGoalStartDate: json['next_goal_start_date'] == null
      ? null
      : DateTime.parse(json['next_goal_start_date'] as String),
  futureGoalKcal: (json['future_goal_kcal'] as num?)?.toDouble(),
);

Map<String, dynamic> _$CalorieWeekOverviewToJson(
  CalorieWeekOverview instance,
) => <String, dynamic>{
  'days': instance.days.map((e) => e.toJson()).toList(),
  'total_consumed_kcal': instance.totalConsumedKcal,
  'total_goal_kcal': instance.totalGoalKcal,
  'remaining_kcal': instance.remainingKcal,
  'balance_start_date': instance.balanceStartDate.toIso8601String(),
  'carryover_before_today_kcal': instance.carryoverBeforeTodayKcal,
  'today_flexible_goal_kcal': instance.todayFlexibleGoalKcal,
  'goal_starts_in_future': instance.goalStartsInFuture,
  'next_goal_start_date': instance.nextGoalStartDate?.toIso8601String(),
  'future_goal_kcal': instance.futureGoalKcal,
};

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
    r'196a369450e8d9fa60d5ca3b47ba906645fb7a1f';

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
    r'860e1a74dd49ea234d51ae43b190620236eed9b9';

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
    r'fa6bdb7a204209613d556f730674b493b7c86b79';

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
