// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_steps_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The steps of the calendar day [day], a date without time, or null when
/// there is nothing to show: steps are off, Health is not ready, the
/// platform has no steps for the app, or the day lies in the future.
/// Today's steps are read again every [dailyStepsTodayRefresh] and when the
/// app comes back.

@ProviderFor(dailySteps)
final dailyStepsProvider = DailyStepsFamily._();

/// The steps of the calendar day [day], a date without time, or null when
/// there is nothing to show: steps are off, Health is not ready, the
/// platform has no steps for the app, or the day lies in the future.
/// Today's steps are read again every [dailyStepsTodayRefresh] and when the
/// app comes back.

final class DailyStepsProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  /// The steps of the calendar day [day], a date without time, or null when
  /// there is nothing to show: steps are off, Health is not ready, the
  /// platform has no steps for the app, or the day lies in the future.
  /// Today's steps are read again every [dailyStepsTodayRefresh] and when the
  /// app comes back.
  DailyStepsProvider._({
    required DailyStepsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'dailyStepsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyStepsHash();

  @override
  String toString() {
    return r'dailyStepsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return dailySteps(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyStepsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyStepsHash() => r'29b20e80b16d63a3307fe97d0466c7d7c86643ff';

/// The steps of the calendar day [day], a date without time, or null when
/// there is nothing to show: steps are off, Health is not ready, the
/// platform has no steps for the app, or the day lies in the future.
/// Today's steps are read again every [dailyStepsTodayRefresh] and when the
/// app comes back.

final class DailyStepsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, DateTime> {
  DailyStepsFamily._()
    : super(
        retry: null,
        name: r'dailyStepsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The steps of the calendar day [day], a date without time, or null when
  /// there is nothing to show: steps are off, Health is not ready, the
  /// platform has no steps for the app, or the day lies in the future.
  /// Today's steps are read again every [dailyStepsTodayRefresh] and when the
  /// app comes back.

  DailyStepsProvider call(DateTime day) =>
      DailyStepsProvider._(argument: day, from: this);

  @override
  String toString() => r'dailyStepsProvider';
}

/// The steps of the [weekDailyStepsDays] days from [weekStart] on, a date
/// without time. An entry is null when its day has nothing to show, lies
/// ahead, or cannot be read.

@ProviderFor(weekDailySteps)
final weekDailyStepsProvider = WeekDailyStepsFamily._();

/// The steps of the [weekDailyStepsDays] days from [weekStart] on, a date
/// without time. An entry is null when its day has nothing to show, lies
/// ahead, or cannot be read.

final class WeekDailyStepsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<int?>>,
          List<int?>,
          FutureOr<List<int?>>
        >
    with $FutureModifier<List<int?>>, $FutureProvider<List<int?>> {
  /// The steps of the [weekDailyStepsDays] days from [weekStart] on, a date
  /// without time. An entry is null when its day has nothing to show, lies
  /// ahead, or cannot be read.
  WeekDailyStepsProvider._({
    required WeekDailyStepsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'weekDailyStepsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weekDailyStepsHash();

  @override
  String toString() {
    return r'weekDailyStepsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<int?>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<int?>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return weekDailySteps(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WeekDailyStepsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weekDailyStepsHash() => r'0d9728868f71bb26bb06c0cfae541d508d5510fd';

/// The steps of the [weekDailyStepsDays] days from [weekStart] on, a date
/// without time. An entry is null when its day has nothing to show, lies
/// ahead, or cannot be read.

final class WeekDailyStepsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<int?>>, DateTime> {
  WeekDailyStepsFamily._()
    : super(
        retry: null,
        name: r'weekDailyStepsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The steps of the [weekDailyStepsDays] days from [weekStart] on, a date
  /// without time. An entry is null when its day has nothing to show, lies
  /// ahead, or cannot be read.

  WeekDailyStepsProvider call(DateTime weekStart) =>
      WeekDailyStepsProvider._(argument: weekStart, from: this);

  @override
  String toString() => r'weekDailyStepsProvider';
}
