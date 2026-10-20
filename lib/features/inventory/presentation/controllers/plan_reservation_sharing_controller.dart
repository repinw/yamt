import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/inventory/data/plan_reservation_repository.dart';
import 'package:yamt/features/inventory/domain/plan_reservation.dart';

part 'plan_reservation_sharing_controller.g.dart';

/// Shares what the own open plans keep from the Vorrat with the household.
/// Its state is what the household got last; null before the first write,
/// after a failed one, and for another household or user. It lives as long
/// as `PlanReservationListener` around the app watches it.
@riverpod
class PlanReservationSharingController
    extends _$PlanReservationSharingController {
  @override
  List<PlanReservation>? build() {
    ref.watch(planReservationRepositoryProvider);
    return null;
  }

  /// Writes [reservations] when they changed: the other members' writes
  /// change the demand too, and writing only a change keeps two devices
  /// from answering each other. Writes run one after the other, so an older
  /// list never lands after a newer one.
  Future<void> share(List<PlanReservation> reservations) {
    if (const ListEquality<PlanReservation>().equals(reservations, state)) {
      return _writes;
    }
    state = reservations;
    final repository = ref.read(planReservationRepositoryProvider);
    return _writes = _writes
        .then((_) => repository.saveOwn(reservations))
        .catchError((Object error, StackTrace stackTrace) {
          log(
            'Sharing the plan reservations failed.',
            name: 'PlanReservationSharingController',
            error: error,
            stackTrace: stackTrace,
          );
          // The next change tries again.
          if (ref.mounted && identical(state, reservations)) state = null;
        });
  }

  Future<void> _writes = Future.value();
}
