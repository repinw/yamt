import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/data/plan_reservation_repository.dart';
import 'package:yamt/features/inventory/domain/plan_reservation.dart';
import 'package:yamt/features/inventory/presentation/controllers/plan_reservation_sharing_controller.dart';
import 'package:yamt/features/inventory/presentation/widgets/plan_reservation_listener.dart';

class _Repository extends Fake implements PlanReservationRepository {
  final saved = <List<PlanReservation>>[];
  bool fails = false;
  Completer<void>? sealing;

  @override
  Future<void> saveOwn(List<PlanReservation> reservations) async {
    if (reservations.isNotEmpty) await sealing?.future;
    saved.add(reservations);
    if (fails) throw StateError('offline');
  }
}

PlanReservation _reservation(double amount) =>
    (stockId: 'pack', amount: amount, at: DateTime(2026, 10, 21, 12));

void main() {
  late _Repository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _Repository();
    container = ProviderContainer(
      overrides: [
        planReservationRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(planReservationSharingControllerProvider, (_, _) {});
  });

  PlanReservationSharingController sharing() =>
      container.read(planReservationSharingControllerProvider.notifier);

  test('shares only a change', () async {
    await sharing().share([_reservation(250)]);
    // The same reservations again, as after another member's change.
    await sharing().share([_reservation(250)]);
    await sharing().share(const []);

    expect(repository.saved, [
      [_reservation(250)],
      const <PlanReservation>[],
    ]);
  });

  test('a later write waits for an earlier one', () async {
    repository.sealing = Completer();
    final first = sharing().share([_reservation(250)]);
    final second = sharing().share(const []);
    repository.sealing!.complete();
    await Future.wait([first, second]);

    expect(repository.saved, [
      [_reservation(250)],
      const <PlanReservation>[],
    ]);
  });

  test('shares again after a failed write', () async {
    repository.fails = true;
    await sharing().share([_reservation(250)]);
    repository.fails = false;
    await sharing().share([_reservation(250)]);

    expect(repository.saved, hasLength(2));
    expect(container.read(planReservationSharingControllerProvider), [
      _reservation(250),
    ]);
  });

  testWidgets('the listener shares the own reservations', (tester) async {
    final own = StreamController<List<PlanReservation>>();
    addTearDown(own.close);
    final listened = _Repository();
    final scope = ProviderContainer(
      overrides: [
        planReservationRepositoryProvider.overrideWithValue(listened),
        ownPlanReservationsProvider.overrideWith((ref) => own.stream.first),
      ],
    );
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: scope,
        child: const PlanReservationListener(child: SizedBox()),
      ),
    );

    own.add([_reservation(100)]);
    await tester.pumpAndSettle();

    expect(listened.saved, [
      [_reservation(100)],
    ]);
  });
}
