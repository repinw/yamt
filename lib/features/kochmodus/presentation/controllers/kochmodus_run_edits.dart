import 'package:uuid/uuid.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kochmodus/application/cook_run_start_service.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_target.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_changes.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';

/// What "+1 Min" adds to a timer.
const kochmodusTimerExtension = Duration(minutes: 1);

/// The run a page of [target] starts from before anything is stored: the
/// draft of the recipe [template] (`null` when it does not exist) for its
/// portions, or free cooking's; `null` for the target of a stored run.
CookRun? kochmodusDraft(
  KochmodusTarget target,
  PreparedMeal? template,
  CookRunStartService start,
) => switch (target) {
  KochmodusRecipeTarget(:final portions) when template != null =>
    start.recipeDraft(template, portions: portions),
  KochmodusFreeTarget(:final runId) => start.freeDraft(runId),
  _ => null,
};

/// A new open line [text] from [origin], with the id [id] or a new one.
CookRunLine kochmodusNewLine(
  String text,
  CookLineOrigin origin, {
  String? id,
}) => CookRunLine(
  id: id ?? const Uuid().v4(),
  text: text,
  origin: origin,
  conversion: null,
  amount: null,
  amountPortions: null,
  amountUnit: null,
  settlement: const LineOpen(),
  weighed: null,
  potId: null,
  addedItemIds: const [],
);

/// The step [run] goes on to once the cook chose its pots: "Kochen", but a
/// run past the pots stays where it is when the cook changes them.
CookRunStep kochmodusAfterPots(CookRun run) => switch (run.step) {
  CookRunStep.pots || CookRunStep.assign => CookRunStep.cook,
  final step => step,
};

/// [run] with [rest] of the line [lineId], such as "200 ml Milch", on the
/// shopping list as a line of its own (`cookRestLineId`), in place of an
/// earlier one.
CookRun kochmodusWithRest(CookRun run, String lineId, String rest) {
  final restId = cookRestLineId(lineId);
  final cleared = run.lineOf(restId) == null ? run : run.removeLine(restId);
  return cleared.addLine(
    kochmodusNewLine(
      rest,
      CookLineOrigin.added,
      id: restId,
    ).copyWith(settlement: const LineShopping()),
  );
}
