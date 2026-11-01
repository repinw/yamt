// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_meal_targets_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Each meal's part of [day]'s kcal target, split by the user's parts of
/// the day, for the meal headings. Null while the pace marker is off, while
/// the day loads, and on a pause day, which has no target; a meal set to 0
/// has no part.

@ProviderFor(diaryMealTargets)
final diaryMealTargetsProvider = DiaryMealTargetsFamily._();

/// Each meal's part of [day]'s kcal target, split by the user's parts of
/// the day, for the meal headings. Null while the pace marker is off, while
/// the day loads, and on a pause day, which has no target; a meal set to 0
/// has no part.

final class DiaryMealTargetsProvider
    extends
        $FunctionalProvider<
          Map<MealType, double>?,
          Map<MealType, double>?,
          Map<MealType, double>?
        >
    with $Provider<Map<MealType, double>?> {
  /// Each meal's part of [day]'s kcal target, split by the user's parts of
  /// the day, for the meal headings. Null while the pace marker is off, while
  /// the day loads, and on a pause day, which has no target; a meal set to 0
  /// has no part.
  DiaryMealTargetsProvider._({
    required DiaryMealTargetsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryMealTargetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryMealTargetsHash();

  @override
  String toString() {
    return r'diaryMealTargetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<MealType, double>?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<MealType, double>? create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryMealTargets(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<MealType, double>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<MealType, double>?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryMealTargetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryMealTargetsHash() => r'd3bc5d8b9aa051228f4c34d6d8f99f3ee3b8bd52';

/// Each meal's part of [day]'s kcal target, split by the user's parts of
/// the day, for the meal headings. Null while the pace marker is off, while
/// the day loads, and on a pause day, which has no target; a meal set to 0
/// has no part.

final class DiaryMealTargetsFamily extends $Family
    with $FunctionalFamilyOverride<Map<MealType, double>?, DateTime> {
  DiaryMealTargetsFamily._()
    : super(
        retry: null,
        name: r'diaryMealTargetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Each meal's part of [day]'s kcal target, split by the user's parts of
  /// the day, for the meal headings. Null while the pace marker is off, while
  /// the day loads, and on a pause day, which has no target; a meal set to 0
  /// has no part.

  DiaryMealTargetsProvider call(DateTime day) =>
      DiaryMealTargetsProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryMealTargetsProvider';
}
