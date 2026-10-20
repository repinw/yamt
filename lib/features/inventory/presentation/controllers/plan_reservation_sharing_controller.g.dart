// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_reservation_sharing_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shares what the own open plans keep from the Vorrat with the household.
/// Its state is what the household got last; null before the first write,
/// after a failed one, and for another household or user. It lives as long
/// as `PlanReservationListener` around the app watches it.

@ProviderFor(PlanReservationSharingController)
final planReservationSharingControllerProvider =
    PlanReservationSharingControllerProvider._();

/// Shares what the own open plans keep from the Vorrat with the household.
/// Its state is what the household got last; null before the first write,
/// after a failed one, and for another household or user. It lives as long
/// as `PlanReservationListener` around the app watches it.
final class PlanReservationSharingControllerProvider
    extends
        $NotifierProvider<
          PlanReservationSharingController,
          List<PlanReservation>?
        > {
  /// Shares what the own open plans keep from the Vorrat with the household.
  /// Its state is what the household got last; null before the first write,
  /// after a failed one, and for another household or user. It lives as long
  /// as `PlanReservationListener` around the app watches it.
  PlanReservationSharingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planReservationSharingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planReservationSharingControllerHash();

  @$internal
  @override
  PlanReservationSharingController create() =>
      PlanReservationSharingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PlanReservation>? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PlanReservation>?>(value),
    );
  }
}

String _$planReservationSharingControllerHash() =>
    r'690d69d7cdd5e1a3e970dae6118c9a6850b16ebb';

/// Shares what the own open plans keep from the Vorrat with the household.
/// Its state is what the household got last; null before the first write,
/// after a failed one, and for another household or user. It lives as long
/// as `PlanReservationListener` around the app watches it.

abstract class _$PlanReservationSharingController
    extends $Notifier<List<PlanReservation>?> {
  List<PlanReservation>? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<List<PlanReservation>?, List<PlanReservation>?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<PlanReservation>?, List<PlanReservation>?>,
              List<PlanReservation>?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
