// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_nutrition_bars_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides real macro totals and targets for one diary day.

@ProviderFor(diaryNutritionBarsData)
final diaryNutritionBarsDataProvider = DiaryNutritionBarsDataFamily._();

/// Provides real macro totals and targets for one diary day.

final class DiaryNutritionBarsDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryNutritionBarsData>,
          DiaryNutritionBarsData,
          FutureOr<DiaryNutritionBarsData>
        >
    with
        $FutureModifier<DiaryNutritionBarsData>,
        $FutureProvider<DiaryNutritionBarsData> {
  /// Provides real macro totals and targets for one diary day.
  DiaryNutritionBarsDataProvider._({
    required DiaryNutritionBarsDataFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'diaryNutritionBarsDataProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$diaryNutritionBarsDataHash();

  @override
  String toString() {
    return r'diaryNutritionBarsDataProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DiaryNutritionBarsData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryNutritionBarsData> create(Ref ref) {
    final argument = this.argument as DateTime;
    return diaryNutritionBarsData(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryNutritionBarsDataProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$diaryNutritionBarsDataHash() =>
    r'32f4c28653f6d37260847f6ec8ce94d534d3b6be';

/// Provides real macro totals and targets for one diary day.

final class DiaryNutritionBarsDataFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DiaryNutritionBarsData>, DateTime> {
  DiaryNutritionBarsDataFamily._()
    : super(
        retry: null,
        name: r'diaryNutritionBarsDataProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides real macro totals and targets for one diary day.

  DiaryNutritionBarsDataProvider call(DateTime day) =>
      DiaryNutritionBarsDataProvider._(argument: day, from: this);

  @override
  String toString() => r'diaryNutritionBarsDataProvider';
}

/// Actions needed by diary nutrition bar widgets.

@ProviderFor(diaryNutritionBarsActions)
final diaryNutritionBarsActionsProvider = DiaryNutritionBarsActionsProvider._();

/// Actions needed by diary nutrition bar widgets.

final class DiaryNutritionBarsActionsProvider
    extends
        $FunctionalProvider<
          DiaryNutritionBarsActions,
          DiaryNutritionBarsActions,
          DiaryNutritionBarsActions
        >
    with $Provider<DiaryNutritionBarsActions> {
  /// Actions needed by diary nutrition bar widgets.
  DiaryNutritionBarsActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryNutritionBarsActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryNutritionBarsActionsHash();

  @$internal
  @override
  $ProviderElement<DiaryNutritionBarsActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryNutritionBarsActions create(Ref ref) {
    return diaryNutritionBarsActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryNutritionBarsActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryNutritionBarsActions>(value),
    );
  }
}

String _$diaryNutritionBarsActionsHash() =>
    r'2df90a6582ed66eb4d11b7885b10f1552c4b4e57';
