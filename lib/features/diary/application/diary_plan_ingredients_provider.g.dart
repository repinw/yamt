// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_plan_ingredients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Kochbuch recipe [templateId] of a plan with its ingredient lines as
/// a plan counts them from the Vorrat now, or null when it is no recipe or
/// gone.

@ProviderFor(diaryPlanIngredients)
final diaryPlanIngredientsProvider = DiaryPlanIngredientsFamily._();

/// The Kochbuch recipe [templateId] of a plan with its ingredient lines as
/// a plan counts them from the Vorrat now, or null when it is no recipe or
/// gone.

final class DiaryPlanIngredientsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryPlanIngredients?>,
          DiaryPlanIngredients?,
          FutureOr<DiaryPlanIngredients?>
        >
    with
        $FutureModifier<DiaryPlanIngredients?>,
        $FutureProvider<DiaryPlanIngredients?> {
  /// The Kochbuch recipe [templateId] of a plan with its ingredient lines as
  /// a plan counts them from the Vorrat now, or null when it is no recipe or
  /// gone.
  DiaryPlanIngredientsProvider._({
    required DiaryPlanIngredientsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'diaryPlanIngredientsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryPlanIngredientsHash();

  @override
  String toString() {
    return r'diaryPlanIngredientsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DiaryPlanIngredients?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryPlanIngredients?> create(Ref ref) {
    final argument = this.argument as String;
    return diaryPlanIngredients(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryPlanIngredientsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryPlanIngredientsHash() =>
    r'2cd58f43aa6346217fbe55382408de0646a93837';

/// The Kochbuch recipe [templateId] of a plan with its ingredient lines as
/// a plan counts them from the Vorrat now, or null when it is no recipe or
/// gone.

final class DiaryPlanIngredientsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DiaryPlanIngredients?>, String> {
  DiaryPlanIngredientsFamily._()
    : super(
        retry: null,
        name: r'diaryPlanIngredientsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Kochbuch recipe [templateId] of a plan with its ingredient lines as
  /// a plan counts them from the Vorrat now, or null when it is no recipe or
  /// gone.

  DiaryPlanIngredientsProvider call(String templateId) =>
      DiaryPlanIngredientsProvider._(argument: templateId, from: this);

  @override
  String toString() => r'diaryPlanIngredientsProvider';
}
