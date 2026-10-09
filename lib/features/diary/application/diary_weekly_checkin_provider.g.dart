// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_weekly_checkin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether [selectedDay] currently has calorie entries in the weekly window.

@ProviderFor(diaryWeeklyCheckInSelectedDayHasEntries)
final diaryWeeklyCheckInSelectedDayHasEntriesProvider =
    DiaryWeeklyCheckInSelectedDayHasEntriesFamily._();

/// Whether [selectedDay] currently has calorie entries in the weekly window.

final class DiaryWeeklyCheckInSelectedDayHasEntriesProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether [selectedDay] currently has calorie entries in the weekly window.
  DiaryWeeklyCheckInSelectedDayHasEntriesProvider._({
    required DiaryWeeklyCheckInSelectedDayHasEntriesFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryWeeklyCheckInSelectedDayHasEntriesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() =>
      _$diaryWeeklyCheckInSelectedDayHasEntriesHash();

  @override
  String toString() {
    return r'diaryWeeklyCheckInSelectedDayHasEntriesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryWeeklyCheckInSelectedDayHasEntries(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryWeeklyCheckInSelectedDayHasEntriesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryWeeklyCheckInSelectedDayHasEntriesHash() =>
    r'ad8e2783b093454eda5fdcd7e606b500679addcc';

/// Whether [selectedDay] currently has calorie entries in the weekly window.

final class DiaryWeeklyCheckInSelectedDayHasEntriesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, DateTime> {
  DiaryWeeklyCheckInSelectedDayHasEntriesFamily._()
    : super(
        retry: null,
        name: r'diaryWeeklyCheckInSelectedDayHasEntriesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [selectedDay] currently has calorie entries in the weekly window.

  DiaryWeeklyCheckInSelectedDayHasEntriesProvider call(DateTime selectedDay) =>
      DiaryWeeklyCheckInSelectedDayHasEntriesProvider._(
        argument: selectedDay,
        from: this,
      );

  @override
  String toString() => r'diaryWeeklyCheckInSelectedDayHasEntriesProvider';
}
