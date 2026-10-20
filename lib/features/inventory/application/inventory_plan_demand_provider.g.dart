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

/// The plan reservations of the other household members, including members
/// who left.

@ProviderFor(otherPlanReservations)
final otherPlanReservationsProvider = OtherPlanReservationsProvider._();

/// The plan reservations of the other household members, including members
/// who left.

final class OtherPlanReservationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MemberPlanReservation>>,
          List<MemberPlanReservation>,
          Stream<List<MemberPlanReservation>>
        >
    with
        $FutureModifier<List<MemberPlanReservation>>,
        $StreamProvider<List<MemberPlanReservation>> {
  /// The plan reservations of the other household members, including members
  /// who left.
  OtherPlanReservationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'otherPlanReservationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$otherPlanReservationsHash();

  @$internal
  @override
  $StreamProviderElement<List<MemberPlanReservation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MemberPlanReservation>> create(Ref ref) {
    return otherPlanReservations(ref);
  }
}

String _$otherPlanReservationsHash() =>
    r'e6bd4ece0a0b8a64beba64505fe80561ee32ea1b';

/// What the open plans take from the Vorrat, foods and cooked meals:
/// "verplant" on Vorrat rows and "fehlt" on plan rows. The plans of the
/// other household members count as "verplant" too.

@ProviderFor(openPlanDemand)
final openPlanDemandProvider = OpenPlanDemandProvider._();

/// What the open plans take from the Vorrat, foods and cooked meals:
/// "verplant" on Vorrat rows and "fehlt" on plan rows. The plans of the
/// other household members count as "verplant" too.

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
  /// "verplant" on Vorrat rows and "fehlt" on plan rows. The plans of the
  /// other household members count as "verplant" too.
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

String _$openPlanDemandHash() => r'9b8d907af2d0ea7664406a47e792fb8635df7f38';

/// What the own open plans keep from the shared Vorrat, to share with the
/// household.

@ProviderFor(ownPlanReservations)
final ownPlanReservationsProvider = OwnPlanReservationsProvider._();

/// What the own open plans keep from the shared Vorrat, to share with the
/// household.

final class OwnPlanReservationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanReservation>>,
          List<PlanReservation>,
          FutureOr<List<PlanReservation>>
        >
    with
        $FutureModifier<List<PlanReservation>>,
        $FutureProvider<List<PlanReservation>> {
  /// What the own open plans keep from the shared Vorrat, to share with the
  /// household.
  OwnPlanReservationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ownPlanReservationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ownPlanReservationsHash();

  @$internal
  @override
  $FutureProviderElement<List<PlanReservation>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanReservation>> create(Ref ref) {
    return ownPlanReservations(ref);
  }
}

String _$ownPlanReservationsHash() =>
    r'6918df59f7f705dfa2b866679d6131d0f50b31f4';

/// The other members whose plans keep stock of each pack or cooked meal, by
/// item or meal id, each with the day of the plan, in the order the plans
/// take it.

@ProviderFor(planStockHolders)
final planStockHoldersProvider = PlanStockHoldersProvider._();

/// The other members whose plans keep stock of each pack or cooked meal, by
/// item or meal id, each with the day of the plan, in the order the plans
/// take it.

final class PlanStockHoldersProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, List<PlanStockHolder>>>,
          Map<String, List<PlanStockHolder>>,
          FutureOr<Map<String, List<PlanStockHolder>>>
        >
    with
        $FutureModifier<Map<String, List<PlanStockHolder>>>,
        $FutureProvider<Map<String, List<PlanStockHolder>>> {
  /// The other members whose plans keep stock of each pack or cooked meal, by
  /// item or meal id, each with the day of the plan, in the order the plans
  /// take it.
  PlanStockHoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planStockHoldersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planStockHoldersHash();

  @$internal
  @override
  $FutureProviderElement<Map<String, List<PlanStockHolder>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, List<PlanStockHolder>>> create(Ref ref) {
    return planStockHolders(ref);
  }
}

String _$planStockHoldersHash() => r'4945e77130c6f8ea27f187ecf96568ba85f82d1d';
