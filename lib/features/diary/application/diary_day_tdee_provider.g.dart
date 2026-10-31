// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_day_tdee_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The daily TDEE estimate in effect on the diary [day] and the day's base
/// goal.
///
/// A day after the newest estimate keeps it, as today keeps yesterday's.

@ProviderFor(diaryDayTdee)
final diaryDayTdeeProvider = DiaryDayTdeeFamily._();

/// The daily TDEE estimate in effect on the diary [day] and the day's base
/// goal.
///
/// A day after the newest estimate keeps it, as today keeps yesterday's.

final class DiaryDayTdeeProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryDayTdee>,
          DiaryDayTdee,
          FutureOr<DiaryDayTdee>
        >
    with $FutureModifier<DiaryDayTdee>, $FutureProvider<DiaryDayTdee> {
  /// The daily TDEE estimate in effect on the diary [day] and the day's base
  /// goal.
  ///
  /// A day after the newest estimate keeps it, as today keeps yesterday's.
  DiaryDayTdeeProvider._({
    required DiaryDayTdeeFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryDayTdeeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryDayTdeeHash();

  @override
  String toString() {
    return r'diaryDayTdeeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DiaryDayTdee> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryDayTdee> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryDayTdee(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryDayTdeeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryDayTdeeHash() => r'ec5fd782a3ad37da5f285d855916db01ff12e1ed';

/// The daily TDEE estimate in effect on the diary [day] and the day's base
/// goal.
///
/// A day after the newest estimate keeps it, as today keeps yesterday's.

final class DiaryDayTdeeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DiaryDayTdee>, DateTime> {
  DiaryDayTdeeFamily._()
    : super(
        retry: null,
        name: r'diaryDayTdeeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The daily TDEE estimate in effect on the diary [day] and the day's base
  /// goal.
  ///
  /// A day after the newest estimate keeps it, as today keeps yesterday's.

  DiaryDayTdeeProvider call(DateTime day) =>
      DiaryDayTdeeProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryDayTdeeProvider';
}
