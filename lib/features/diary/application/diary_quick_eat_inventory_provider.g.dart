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
        dependencies: <ProviderOrFamily>[
          inventoryItemsControllerProvider,
          preparedMealsControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          DiaryQuickEatInventoryProvider.$allTransitiveDependencies0,
          DiaryQuickEatInventoryProvider.$allTransitiveDependencies1,
          DiaryQuickEatInventoryProvider.$allTransitiveDependencies2,
          DiaryQuickEatInventoryProvider.$allTransitiveDependencies3,
          DiaryQuickEatInventoryProvider.$allTransitiveDependencies4,
          DiaryQuickEatInventoryProvider.$allTransitiveDependencies5,
        },
      );

  static final $allTransitiveDependencies0 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies1 =
      InventoryItemsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      InventoryItemsControllerProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 = preparedMealsControllerProvider;
  static final $allTransitiveDependencies4 =
      PreparedMealsControllerProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies5 =
      PreparedMealsControllerProvider.$allTransitiveDependencies3;

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
    r'063e107b310280afbc8b3d3bb0f79cdc0b5413b0';

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
        dependencies: <ProviderOrFamily>[
          inventoryItemsControllerProvider,
          preparedMealsControllerProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          DiaryQuickEatInventoryActionsProvider.$allTransitiveDependencies0,
          DiaryQuickEatInventoryActionsProvider.$allTransitiveDependencies1,
          DiaryQuickEatInventoryActionsProvider.$allTransitiveDependencies2,
          DiaryQuickEatInventoryActionsProvider.$allTransitiveDependencies3,
          DiaryQuickEatInventoryActionsProvider.$allTransitiveDependencies4,
          DiaryQuickEatInventoryActionsProvider.$allTransitiveDependencies5,
        },
      );

  static final $allTransitiveDependencies0 = inventoryItemsControllerProvider;
  static final $allTransitiveDependencies1 =
      InventoryItemsControllerProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      InventoryItemsControllerProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 = preparedMealsControllerProvider;
  static final $allTransitiveDependencies4 =
      PreparedMealsControllerProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies5 =
      PreparedMealsControllerProvider.$allTransitiveDependencies3;

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
    r'1dbb3053f6509b7069316d09fc6f8e6afce3ed83';
