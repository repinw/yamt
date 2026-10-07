// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_plan_demand_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The open plans from today to the last day that can be planned. Overdue
/// plans do not count.

@ProviderFor(openPlans)
final openPlansProvider = OpenPlansProvider._();

/// The open plans from today to the last day that can be planned. Overdue
/// plans do not count.

final class OpenPlansProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CalorieEntry>>,
          List<CalorieEntry>,
          FutureOr<List<CalorieEntry>>
        >
    with
        $FutureModifier<List<CalorieEntry>>,
        $FutureProvider<List<CalorieEntry>> {
  /// The open plans from today to the last day that can be planned. Overdue
  /// plans do not count.
  OpenPlansProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openPlansProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openPlansHash();

  @$internal
  @override
  $FutureProviderElement<List<CalorieEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CalorieEntry>> create(Ref ref) {
    return openPlans(ref);
  }
}

String _$openPlansHash() => r'd03adcf8048e946347f1e28c8472321b8e00a198';

/// What the open plans take from the Vorrat: "verplant" on Vorrat rows and
/// "fehlt" on plan rows.

@ProviderFor(openPlanDemand)
final openPlanDemandProvider = OpenPlanDemandProvider._();

/// What the open plans take from the Vorrat: "verplant" on Vorrat rows and
/// "fehlt" on plan rows.

final class OpenPlanDemandProvider
    extends
        $FunctionalProvider<
          AsyncValue<InventoryPlanDemand>,
          InventoryPlanDemand,
          FutureOr<InventoryPlanDemand>
        >
    with
        $FutureModifier<InventoryPlanDemand>,
        $FutureProvider<InventoryPlanDemand> {
  /// What the open plans take from the Vorrat: "verplant" on Vorrat rows and
  /// "fehlt" on plan rows.
  OpenPlanDemandProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openPlanDemandProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openPlanDemandHash();

  @$internal
  @override
  $FutureProviderElement<InventoryPlanDemand> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InventoryPlanDemand> create(Ref ref) {
    return openPlanDemand(ref);
  }
}

String _$openPlanDemandHash() => r'3df3780169622f20cacf6f66ad5d16711e52213c';
