// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_meal_kcals_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The kcal of each meal of the normalized [day], as the meal headings
/// below the dashboard count them: eaten, plus the plans the heading
/// counts on top. Null while the day loads.

@ProviderFor(diaryMealKcals)
final diaryMealKcalsProvider = DiaryMealKcalsFamily._();

/// The kcal of each meal of the normalized [day], as the meal headings
/// below the dashboard count them: eaten, plus the plans the heading
/// counts on top. Null while the day loads.

final class DiaryMealKcalsProvider
    extends
        $FunctionalProvider<
          List<DiaryMealKcal>?,
          List<DiaryMealKcal>?,
          List<DiaryMealKcal>?
        >
    with $Provider<List<DiaryMealKcal>?> {
  /// The kcal of each meal of the normalized [day], as the meal headings
  /// below the dashboard count them: eaten, plus the plans the heading
  /// counts on top. Null while the day loads.
  DiaryMealKcalsProvider._({
    required DiaryMealKcalsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryMealKcalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryMealKcalsHash();

  @override
  String toString() {
    return r'diaryMealKcalsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<List<DiaryMealKcal>?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<DiaryMealKcal>? create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryMealKcals(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DiaryMealKcal>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DiaryMealKcal>?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryMealKcalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryMealKcalsHash() => r'e395d3148eb161faa6d8d568b6ae33dc6f01980a';

/// The kcal of each meal of the normalized [day], as the meal headings
/// below the dashboard count them: eaten, plus the plans the heading
/// counts on top. Null while the day loads.

final class DiaryMealKcalsFamily extends $Family
    with $FunctionalFamilyOverride<List<DiaryMealKcal>?, DateTime> {
  DiaryMealKcalsFamily._()
    : super(
        retry: null,
        name: r'diaryMealKcalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The kcal of each meal of the normalized [day], as the meal headings
  /// below the dashboard count them: eaten, plus the plans the heading
  /// counts on top. Null while the day loads.

  DiaryMealKcalsProvider call(DateTime day) =>
      DiaryMealKcalsProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryMealKcalsProvider';
}
