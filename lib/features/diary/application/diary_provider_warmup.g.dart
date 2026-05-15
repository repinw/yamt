// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_provider_warmup.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Keeps expensive providers warm while the diary page is open.

@ProviderFor(diaryProviderWarmup)
final diaryProviderWarmupProvider = DiaryProviderWarmupProvider._();

/// Keeps expensive providers warm while the diary page is open.

final class DiaryProviderWarmupProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Keeps expensive providers warm while the diary page is open.
  DiaryProviderWarmupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryProviderWarmupProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          inventoryItemsControllerProvider,
          preparedMealsControllerProvider,
          calorieEntryDeleteFlowProvider,
          inventoryBackedCalorieEntrySaveFlowProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          DiaryProviderWarmupProvider.$allTransitiveDependencies0,
          DiaryProviderWarmupProvider.$allTransitiveDependencies1,
          DiaryProviderWarmupProvider.$allTransitiveDependencies2,
          DiaryProviderWarmupProvider.$allTransitiveDependencies3,
          DiaryProviderWarmupProvider.$allTransitiveDependencies4,
        },
      );

  static final $allTransitiveDependencies0 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies1 =
      InventoryItemsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 = preparedMealsControllerProvider;
  static final $allTransitiveDependencies3 = calorieEntryDeleteFlowProvider;
  static final $allTransitiveDependencies4 =
      inventoryBackedCalorieEntrySaveFlowProvider;

  @override
  String debugGetCreateSourceHash() => _$diaryProviderWarmupHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return diaryProviderWarmup(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$diaryProviderWarmupHash() =>
    r'c27b58206b21eac4247d8b93bbaa2ce0690cbe69';
