// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_quick_eat_data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Watches all inventory items for quick-eat consumers.

@ProviderFor(inventoryQuickEatItems)
final inventoryQuickEatItemsProvider = InventoryQuickEatItemsProvider._();

/// Watches all inventory items for quick-eat consumers.

final class InventoryQuickEatItemsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryItem>>,
          List<InventoryItem>,
          Stream<List<InventoryItem>>
        >
    with
        $FutureModifier<List<InventoryItem>>,
        $StreamProvider<List<InventoryItem>> {
  /// Watches all inventory items for quick-eat consumers.
  InventoryQuickEatItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryQuickEatItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryQuickEatItemsHash();

  @$internal
  @override
  $StreamProviderElement<List<InventoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InventoryItem>> create(Ref ref) {
    return inventoryQuickEatItems(ref);
  }
}

String _$inventoryQuickEatItemsHash() =>
    r'4bc5ccd1331ec05ae829db7ad848aa757474a542';

/// Watches all prepared meals for quick-eat consumers.

@ProviderFor(inventoryQuickEatMeals)
final inventoryQuickEatMealsProvider = InventoryQuickEatMealsProvider._();

/// Watches all prepared meals for quick-eat consumers.

final class InventoryQuickEatMealsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PreparedMeal>>,
          List<PreparedMeal>,
          Stream<List<PreparedMeal>>
        >
    with
        $FutureModifier<List<PreparedMeal>>,
        $StreamProvider<List<PreparedMeal>> {
  /// Watches all prepared meals for quick-eat consumers.
  InventoryQuickEatMealsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryQuickEatMealsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryQuickEatMealsHash();

  @$internal
  @override
  $StreamProviderElement<List<PreparedMeal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PreparedMeal>> create(Ref ref) {
    return inventoryQuickEatMeals(ref);
  }
}

String _$inventoryQuickEatMealsHash() =>
    r'e7a6be07765ffae1a0ef1e29c5d36bd8bc607349';

/// Loads live inventory data for quick-eat pickers.

@ProviderFor(inventoryQuickEatInventory)
final inventoryQuickEatInventoryProvider =
    InventoryQuickEatInventoryProvider._();

/// Loads live inventory data for quick-eat pickers.

final class InventoryQuickEatInventoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<InventoryQuickEatInventoryData>,
          InventoryQuickEatInventoryData,
          FutureOr<InventoryQuickEatInventoryData>
        >
    with
        $FutureModifier<InventoryQuickEatInventoryData>,
        $FutureProvider<InventoryQuickEatInventoryData> {
  /// Loads live inventory data for quick-eat pickers.
  InventoryQuickEatInventoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryQuickEatInventoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryQuickEatInventoryHash();

  @$internal
  @override
  $FutureProviderElement<InventoryQuickEatInventoryData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InventoryQuickEatInventoryData> create(Ref ref) {
    return inventoryQuickEatInventory(ref);
  }
}

String _$inventoryQuickEatInventoryHash() =>
    r'fc1c4352ffc2655f7ec22243a703003215aab586';

/// The Vorrat meal [mealId] as it is stored now, or `null` while the Vorrat
/// has no meal with that id. Every meal page reads its meal here.

@ProviderFor(livePreparedMeal)
final livePreparedMealProvider = LivePreparedMealFamily._();

/// The Vorrat meal [mealId] as it is stored now, or `null` while the Vorrat
/// has no meal with that id. Every meal page reads its meal here.

final class LivePreparedMealProvider
    extends
        $FunctionalProvider<
          AsyncValue<PreparedMeal?>,
          AsyncValue<PreparedMeal?>,
          AsyncValue<PreparedMeal?>
        >
    with $Provider<AsyncValue<PreparedMeal?>> {
  /// The Vorrat meal [mealId] as it is stored now, or `null` while the Vorrat
  /// has no meal with that id. Every meal page reads its meal here.
  LivePreparedMealProvider._({
    required LivePreparedMealFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'livePreparedMealProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$livePreparedMealHash();

  @override
  String toString() {
    return r'livePreparedMealProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<PreparedMeal?>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<PreparedMeal?> create(Ref ref) {
    final argument = this.argument as String;
    return livePreparedMeal(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<PreparedMeal?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<PreparedMeal?>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LivePreparedMealProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$livePreparedMealHash() => r'962c7c686a43a46d8426d1ceccfe708a8ea7592c';

/// The Vorrat meal [mealId] as it is stored now, or `null` while the Vorrat
/// has no meal with that id. Every meal page reads its meal here.

final class LivePreparedMealFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<PreparedMeal?>, String> {
  LivePreparedMealFamily._()
    : super(
        retry: null,
        name: r'livePreparedMealProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The Vorrat meal [mealId] as it is stored now, or `null` while the Vorrat
  /// has no meal with that id. Every meal page reads its meal here.

  LivePreparedMealProvider call(String mealId) =>
      LivePreparedMealProvider._(argument: mealId, from: this);

  @override
  String toString() => r'livePreparedMealProvider';
}
