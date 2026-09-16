// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'diary_quick_eat_inventory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides selectable inventory foods for the diary quick-eat picker.

@ProviderFor(diaryQuickEatInventory)
final diaryQuickEatInventoryProvider = DiaryQuickEatInventoryProvider._();

/// Provides selectable inventory foods for the diary quick-eat picker.

final class DiaryQuickEatInventoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiaryQuickEatInventoryData>,
          DiaryQuickEatInventoryData,
          FutureOr<DiaryQuickEatInventoryData>
        >
    with
        $FutureModifier<DiaryQuickEatInventoryData>,
        $FutureProvider<DiaryQuickEatInventoryData> {
  /// Provides selectable inventory foods for the diary quick-eat picker.
  DiaryQuickEatInventoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryQuickEatInventoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryQuickEatInventoryHash();

  @$internal
  @override
  $FutureProviderElement<DiaryQuickEatInventoryData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DiaryQuickEatInventoryData> create(Ref ref) {
    return diaryQuickEatInventory(ref);
  }
}

String _$diaryQuickEatInventoryHash() =>
    r'f432e977c673dd6979fd129d2a031ae06cad5a21';

/// Provides inventory mutations used by diary quick-eat.

@ProviderFor(diaryQuickEatInventoryActions)
final diaryQuickEatInventoryActionsProvider =
    DiaryQuickEatInventoryActionsProvider._();

/// Provides inventory mutations used by diary quick-eat.

final class DiaryQuickEatInventoryActionsProvider
    extends
        $FunctionalProvider<
          DiaryQuickEatInventoryActions,
          DiaryQuickEatInventoryActions,
          DiaryQuickEatInventoryActions
        >
    with $Provider<DiaryQuickEatInventoryActions> {
  /// Provides inventory mutations used by diary quick-eat.
  DiaryQuickEatInventoryActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diaryQuickEatInventoryActionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diaryQuickEatInventoryActionsHash();

  @$internal
  @override
  $ProviderElement<DiaryQuickEatInventoryActions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DiaryQuickEatInventoryActions create(Ref ref) {
    return diaryQuickEatInventoryActions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiaryQuickEatInventoryActions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiaryQuickEatInventoryActions>(
        value,
      ),
    );
  }
}

String _$diaryQuickEatInventoryActionsHash() =>
    r'efdb869e96d0034ccf58d9013b8a79e5f1e7a0ed';
