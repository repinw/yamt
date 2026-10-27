// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_plan_ingredient_rows_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The recipe lines of the plan on its details page, each with the plan
/// foods it takes, and the foods no line takes, or null when the plan comes
/// from no Kochbuch recipe.

@ProviderFor(diaryPlanIngredientRows)
final diaryPlanIngredientRowsProvider = DiaryPlanIngredientRowsFamily._();

/// The recipe lines of the plan on its details page, each with the plan
/// foods it takes, and the foods no line takes, or null when the plan comes
/// from no Kochbuch recipe.

final class DiaryPlanIngredientRowsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryPlanIngredientRows?>,
          DiaryPlanIngredientRows?,
          FutureOr<DiaryPlanIngredientRows?>
        >
    with
        $FutureModifier<DiaryPlanIngredientRows?>,
        $FutureProvider<DiaryPlanIngredientRows?> {
  /// The recipe lines of the plan on its details page, each with the plan
  /// foods it takes, and the foods no line takes, or null when the plan comes
  /// from no Kochbuch recipe.
  DiaryPlanIngredientRowsProvider._({
    required DiaryPlanIngredientRowsFamily super.from,
    required (String, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'diaryPlanIngredientRowsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryPlanIngredientRowsHash();

  @override
  String toString() {
    return r'diaryPlanIngredientRowsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DiaryPlanIngredientRows?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryPlanIngredientRows?> create(Ref ref) {
    final argument = this.argument as (String, DateTime, DateTime);
    return diaryPlanIngredientRows(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryPlanIngredientRowsProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryPlanIngredientRowsHash() =>
    r'3364acf06408d8360d95611ba948cabf1f23a809';

/// The recipe lines of the plan on its details page, each with the plan
/// foods it takes, and the foods no line takes, or null when the plan comes
/// from no Kochbuch recipe.

final class DiaryPlanIngredientRowsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<DiaryPlanIngredientRows?>,
          (String, DateTime, DateTime)
        > {
  DiaryPlanIngredientRowsFamily._()
    : super(
        retry: null,
        name: r'diaryPlanIngredientRowsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The recipe lines of the plan on its details page, each with the plan
  /// foods it takes, and the foods no line takes, or null when the plan comes
  /// from no Kochbuch recipe.

  DiaryPlanIngredientRowsProvider call(
    String planId,
    DateTime planDay,
    DateTime today,
  ) => DiaryPlanIngredientRowsProvider._(
    argument: (planId, planDay, today),
    from: this,
  );

  @override
  String toString() => r'diaryPlanIngredientRowsProvider';
}
