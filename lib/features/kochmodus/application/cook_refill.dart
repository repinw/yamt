import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';

/// [run] with its line `lineId` taking from the Vorrat items `itemIds` in
/// that order (`KochmodusController.refillTakes`).
typedef CookRefill = CookRun Function(
  CookRun run,
  String lineId,
  List<String> itemIds,
);

/// [run] with the line [id], when it is assigned, taking again from the same
/// items in the same order ([refill]); any other line stays as it is.
CookRun cookRefillLine(CookRun run, String id, CookRefill refill) =>
    switch (run.lineOf(id)?.settlement) {
      LineAssigned(:final takes) => refill(run, id, [
        for (final take in takes) take.itemId,
      ]),
      _ => run,
    };

/// [run] as "Zuweisen" opens it: back from the shopping a paused run's
/// shopping lines are open again, and cut takes are filled up
/// ([cookRefillCut]).
CookRun cookRunOpened(CookRun run, CookRefill refill) => cookRefillCut(
  run.step == CookRunStep.paused ? run.reopenShopping() : run,
  refill,
);

/// [run] with every assigned line that the cook did not weigh taking again
/// from its own items in their order ([refill]) where that gives none of
/// them less and one of them more: a take cut for too little stock follows
/// the stock once more is there. A take is never cut here, and a line that
/// takes nothing waits as it is (for a weight or another food).
CookRun cookRefillCut(CookRun run, CookRefill refill) {
  var refilled = run;
  for (final line in run.lines) {
    if (line.weighed != null) continue;
    if (line.settlement case LineAssigned(:final takes)
        when takes.any((take) => take.amount > 0)) {
      final next = refill(refilled, line.id, [
        for (final take in takes) take.itemId,
      ]);
      if (_grows(takes, next.lineOf(line.id)?.settlement)) refilled = next;
    }
  }
  return refilled;
}

// Whether [after] takes from the items of [before] no less of each and more
// of one.
bool _grows(List<ItemTake> before, LineSettlement? after) {
  if (after is! LineAssigned) return false;
  final now = {for (final take in after.takes) take.itemId: take.amount};
  return before.every((take) => (now[take.itemId] ?? 0) >= take.amount) &&
      before.any((take) => (now[take.itemId] ?? 0) > take.amount) &&
      now.keys.every(before.map((take) => take.itemId).contains);
}
