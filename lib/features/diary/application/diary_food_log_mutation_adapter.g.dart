// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_food_log_mutation_adapter.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Adapts calorie mutations for a single Diary input session.

@ProviderFor(diaryFoodLogMutationAdapter)
final diaryFoodLogMutationAdapterProvider =
    DiaryFoodLogMutationAdapterProvider._();

/// Adapts calorie mutations for a single Diary input session.

final class DiaryFoodLogMutationAdapterProvider
    extends
        $FunctionalProvider<
          DiaryFoodLogMutationAdapter,
          DiaryFoodLogMutationAdapter,
          DiaryFoodLogMutationAdapter
        >
    with $Provider<DiaryFoodLogMutationAdapter> {
  /// Adapts calorie mutations for a single Diary input session.
  DiaryFoodLogMutationAdapterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryFoodLogMutationAdapterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryFoodLogMutationAdapterHash();

  @$internal
  @override
  $ProviderElement<DiaryFoodLogMutationAdapter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryFoodLogMutationAdapter create(Ref ref) {
    return diaryFoodLogMutationAdapter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryFoodLogMutationAdapter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryFoodLogMutationAdapter>(value),
    );
  }
}

String _$diaryFoodLogMutationAdapterHash() =>
    r'24f14be7f86b5bb61e68ad1b0a61f845b9e2f441';
