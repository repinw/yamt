// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_reservation_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The plan reservation repository of the signed-in user's household.

@ProviderFor(planReservationRepository)
final planReservationRepositoryProvider = PlanReservationRepositoryProvider._();

/// The plan reservation repository of the signed-in user's household.

final class PlanReservationRepositoryProvider
    extends
        $FunctionalProvider<
          PlanReservationRepository,
          PlanReservationRepository,
          PlanReservationRepository
        >
    with $Provider<PlanReservationRepository> {
  /// The plan reservation repository of the signed-in user's household.
  PlanReservationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planReservationRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planReservationRepositoryHash();

  @$internal
  @override
  $ProviderElement<PlanReservationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanReservationRepository create(Ref ref) {
    return planReservationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanReservationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanReservationRepository>(value),
    );
  }
}

String _$planReservationRepositoryHash() =>
    r'e93d9798fb1acc2b1834c91637965d8086a55c88';
