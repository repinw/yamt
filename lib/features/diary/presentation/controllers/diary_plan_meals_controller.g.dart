// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_plan_meals_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Vorrat meal of each meal plan on [day], by plan id, as the meal is
/// now. Loads the meals only when the day has a meal plan.

@ProviderFor(diaryPlanMeals)
final diaryPlanMealsProvider = DiaryPlanMealsFamily._();

/// The Vorrat meal of each meal plan on [day], by plan id, as the meal is
/// now. Loads the meals only when the day has a meal plan.

final class DiaryPlanMealsProvider
    extends
        $FunctionalProvider<
          Map<String, PreparedMeal>,
          Map<String, PreparedMeal>,
          Map<String, PreparedMeal>
        >
    with $Provider<Map<String, PreparedMeal>> {
  /// The Vorrat meal of each meal plan on [day], by plan id, as the meal is
  /// now. Loads the meals only when the day has a meal plan.
  DiaryPlanMealsProvider._({
    required DiaryPlanMealsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryPlanMealsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryPlanMealsHash();

  @override
  String toString() {
    return r'diaryPlanMealsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Map<String, PreparedMeal>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Map<String, PreparedMeal> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryPlanMeals(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, PreparedMeal> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, PreparedMeal>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryPlanMealsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryPlanMealsHash() => r'cab03c18ae8c5362f824f1999b7b98503e75ce01';

/// The Vorrat meal of each meal plan on [day], by plan id, as the meal is
/// now. Loads the meals only when the day has a meal plan.

final class DiaryPlanMealsFamily extends $Family
    with $FunctionalFamilyOverride<Map<String, PreparedMeal>, DateTime> {
  DiaryPlanMealsFamily._()
    : super(
        retry: null,
        name: r'diaryPlanMealsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Vorrat meal of each meal plan on [day], by plan id, as the meal is
  /// now. Loads the meals only when the day has a meal plan.

  DiaryPlanMealsProvider call(DateTime day) =>
      DiaryPlanMealsProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryPlanMealsProvider';
}
