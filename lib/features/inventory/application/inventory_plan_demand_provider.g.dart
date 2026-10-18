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

/// The Kochbuch recipes and Vorlagen that recipe plans come from.

@ProviderFor(planTemplates)
final planTemplatesProvider = PlanTemplatesProvider._();

/// The Kochbuch recipes and Vorlagen that recipe plans come from.

final class PlanTemplatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PreparedMeal>>,
          List<PreparedMeal>,
          Stream<List<PreparedMeal>>
        >
    with
        $FutureModifier<List<PreparedMeal>>,
        $StreamProvider<List<PreparedMeal>> {
  /// The Kochbuch recipes and Vorlagen that recipe plans come from.
  PlanTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planTemplatesHash();

  @$internal
  @override
  $StreamProviderElement<List<PreparedMeal>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<PreparedMeal>> create(Ref ref) {
    return planTemplates(ref);
  }
}

String _$planTemplatesHash() => r'3562b13ff637859650b5e8be77431fa1af8739ff';

/// What the open plans take from the Vorrat, foods and cooked meals:
/// "verplant" on Vorrat rows and "fehlt" on plan rows.

@ProviderFor(openPlanDemand)
final openPlanDemandProvider = OpenPlanDemandProvider._();

/// What the open plans take from the Vorrat, foods and cooked meals:
/// "verplant" on Vorrat rows and "fehlt" on plan rows.

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
  /// What the open plans take from the Vorrat, foods and cooked meals:
  /// "verplant" on Vorrat rows and "fehlt" on plan rows.
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

String _$openPlanDemandHash() => r'977c3df9872be657aeb17e69dada46a280f091d1';
