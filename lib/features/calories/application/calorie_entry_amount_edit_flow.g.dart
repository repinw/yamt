// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calorie_entry_amount_edit_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides inventory stock adjustment when inventory is wired.

@ProviderFor(calorieInventoryStockAdjuster)
final calorieInventoryStockAdjusterProvider =
    CalorieInventoryStockAdjusterProvider._();

/// Provides inventory stock adjustment when inventory is wired.

final class CalorieInventoryStockAdjusterProvider
    extends
        $FunctionalProvider<
          CalorieInventoryStockAdjuster?,
          CalorieInventoryStockAdjuster?,
          CalorieInventoryStockAdjuster?
        >
    with $Provider<CalorieInventoryStockAdjuster?> {
  /// Provides inventory stock adjustment when inventory is wired.
  CalorieInventoryStockAdjusterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieInventoryStockAdjusterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieInventoryStockAdjusterHash();

  @$internal
  @override
  $ProviderElement<CalorieInventoryStockAdjuster?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieInventoryStockAdjuster? create(Ref ref) {
    return calorieInventoryStockAdjuster(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieInventoryStockAdjuster? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieInventoryStockAdjuster?>(
        value,
      ),
    );
  }
}

String _$calorieInventoryStockAdjusterHash() =>
    r'237555787b4c3cc6145bc9f165745e7c1a152594';

/// Provides the amount edit flow of logged entries.

@ProviderFor(calorieEntryAmountEditFlow)
final calorieEntryAmountEditFlowProvider =
    CalorieEntryAmountEditFlowProvider._();

/// Provides the amount edit flow of logged entries.

final class CalorieEntryAmountEditFlowProvider
    extends
        $FunctionalProvider<
          CalorieEntryAmountEditFlow,
          CalorieEntryAmountEditFlow,
          CalorieEntryAmountEditFlow
        >
    with $Provider<CalorieEntryAmountEditFlow> {
  /// Provides the amount edit flow of logged entries.
  CalorieEntryAmountEditFlowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calorieEntryAmountEditFlowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calorieEntryAmountEditFlowHash();

  @$internal
  @override
  $ProviderElement<CalorieEntryAmountEditFlow> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalorieEntryAmountEditFlow create(Ref ref) {
    return calorieEntryAmountEditFlow(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalorieEntryAmountEditFlow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalorieEntryAmountEditFlow>(value),
    );
  }
}

String _$calorieEntryAmountEditFlowHash() =>
    r'feffeaebbb9550b3b02066cdd0073b718d84c523';
