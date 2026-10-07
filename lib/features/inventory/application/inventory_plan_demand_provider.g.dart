// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_plan_demand_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the open plans from today on take from the Vorrat: "verplant" on
/// Vorrat rows and "fehlt" on plan rows.

@ProviderFor(openPlanDemand)
final openPlanDemandProvider = OpenPlanDemandProvider._();

/// What the open plans from today on take from the Vorrat: "verplant" on
/// Vorrat rows and "fehlt" on plan rows.

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
  /// What the open plans from today on take from the Vorrat: "verplant" on
  /// Vorrat rows and "fehlt" on plan rows.
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

String _$openPlanDemandHash() => r'c277b42bf7b3f85e00f4b73fcffda770c433a1e3';
