// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_entries_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides calorie entries for one normalized diary day.

@ProviderFor(diaryEntriesForDay)
final diaryEntriesForDayProvider = DiaryEntriesForDayFamily._();

/// Provides calorie entries for one normalized diary day.

final class DiaryEntriesForDayProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CalorieEntry>>,
          List<CalorieEntry>,
          Stream<List<CalorieEntry>>
        >
    with
        $FutureModifier<List<CalorieEntry>>,
        $StreamProvider<List<CalorieEntry>> {
  /// Provides calorie entries for one normalized diary day.
  DiaryEntriesForDayProvider._({
    required DiaryEntriesForDayFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryEntriesForDayProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryEntriesForDayHash();

  @override
  String toString() {
    return r'diaryEntriesForDayProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CalorieEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CalorieEntry>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryEntriesForDay(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryEntriesForDayProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryEntriesForDayHash() =>
    r'6033a82c44bb1f6e20e92f3797d1b7fd98175aee';

/// Provides calorie entries for one normalized diary day.

final class DiaryEntriesForDayFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<CalorieEntry>>, DateTime> {
  DiaryEntriesForDayFamily._()
    : super(
        retry: null,
        name: r'diaryEntriesForDayProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides calorie entries for one normalized diary day.

  DiaryEntriesForDayProvider call(DateTime day) =>
      DiaryEntriesForDayProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryEntriesForDayProvider';
}
