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
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          DiaryProviderWarmupProvider.$allTransitiveDependencies0,
          DiaryProviderWarmupProvider.$allTransitiveDependencies1,
          DiaryProviderWarmupProvider.$allTransitiveDependencies2,
          DiaryProviderWarmupProvider.$allTransitiveDependencies3,
          DiaryProviderWarmupProvider.$allTransitiveDependencies4,
          DiaryProviderWarmupProvider.$allTransitiveDependencies5,
          DiaryProviderWarmupProvider.$allTransitiveDependencies6,
        },
      );

  static final $allTransitiveDependencies0 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies1 =
      InventoryItemsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      InventoryItemsControllerProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      InventoryItemsControllerProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 = preparedMealsControllerProvider;
  static final $allTransitiveDependencies5 =
      PreparedMealsControllerProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies6 =
      PreparedMealsControllerProvider.$allTransitiveDependencies4;

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
    r'41be427516bedefc0bffddd1f4dd04c287c98961';

/// Current diary day that should be warmed.

@ProviderFor(diaryProviderWarmupToday)
final diaryProviderWarmupTodayProvider = DiaryProviderWarmupTodayProvider._();

/// Current diary day that should be warmed.

final class DiaryProviderWarmupTodayProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// Current diary day that should be warmed.
  DiaryProviderWarmupTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryProviderWarmupTodayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryProviderWarmupTodayHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return diaryProviderWarmupToday(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$diaryProviderWarmupTodayHash() =>
    r'326b3abec9f0ebb45de96cf5a867ddf7203bce2a';
