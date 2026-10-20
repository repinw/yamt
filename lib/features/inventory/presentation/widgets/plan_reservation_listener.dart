import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/presentation/controllers/plan_reservation_sharing_controller.dart';

/// Shares what the own open plans keep from the Vorrat with the household,
/// so the other members see it as "verplant". Wraps the app.
class PlanReservationListener extends ConsumerWidget {
  /// Creates the listener around [child].
  const new({required this.child, super.key});

  /// The app.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps what the household got last.
    ref.watch(planReservationSharingControllerProvider);
    ref.listen(ownPlanReservationsProvider, (_, next) {
      // A failed read keeps the shared reservations; the next change shares.
      if (next case AsyncData(value: final reservations)) {
        unawaited(
          ref
              .read(planReservationSharingControllerProvider.notifier)
              .share(reservations),
        );
      }
    });
    return child;
  }
}
