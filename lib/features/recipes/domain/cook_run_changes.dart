import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The changes a cook makes to a run. Each returns the changed run and
/// touches nothing else: ids and times come in as arguments. A change that
/// names a line, pot or timer the run does not have throws a [StateError],
/// for example when another device removed it meanwhile.
extension CookRunChanges on CookRun {
  /// The run in [pots]. Lines and meals of a pot that is no longer chosen
  /// go back to the first pot.
  CookRun withPots(List<CookPot> pots, {required bool inCans}) {
    final ids = {for (final pot in pots) pot.id};
    return copyWith(
      pots: CookPotsChosen(pots: pots, inCans: inCans),
      lines: [
        for (final line in lines)
          if (ids.contains(line.potId))
            line
          else
            line.copyWith(potId: () => null),
      ],
      meals: [
        for (final meal in meals)
          if (ids.contains(meal.potId)) meal,
      ],
    );
  }

  /// The run without a pot: the cook counts pieces.
  CookRun withCounted() => copyWith(
    pots: const CookCounted(),
    lines: [for (final line in lines) line.copyWith(potId: () => null)],
    meals: [
      for (final meal in meals)
        if (meal.potId == countedMealPotId) meal,
    ],
  );

  /// The run on [step].
  CookRun toStep(CookRunStep step) => copyWith(step: step);

  /// The line [lineId] settled as [settlement].
  CookRun settle(String lineId, LineSettlement settlement) =>
      _line(lineId, (line) => line.copyWith(settlement: settlement));

  /// The line [lineId] taking [takes]; no takes open it again. Throws an
  /// [ArgumentError] when an item appears twice (see [LineAssigned]).
  CookRun withTakes(String lineId, List<ItemTake> takes) =>
      settle(lineId, takes.isEmpty ? const LineOpen() : LineAssigned(takes));

  /// The line [lineId] with [amount] in its own unit for the run's current
  /// portions, or in [unit] when its text names none; `null` goes back to the
  /// recipe's. The caller refills the takes.
  CookRun withAmount(
    String lineId,
    int? amount, {
    TemplateIngredientUnit? unit,
  }) {
    if (amount != null && amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be negative');
    }
    return _line(
      lineId,
      (line) => line.copyWith(
        amount: () => amount,
        amountPortions: () => amount == null ? null : portions,
        amountUnit: () => amount == null ? null : unit,
      ),
    );
  }

  /// The line [lineId] weighed at [grams]; `null` clears the weight.
  CookRun weigh(String lineId, int? grams) {
    if (grams != null && grams < 0) {
      throw ArgumentError.value(grams, 'grams', 'must not be negative');
    }
    return _line(lineId, (line) => line.copyWith(weighed: () => grams));
  }

  /// The run with [line] at the end. Throws a [StateError] when its id is
  /// taken.
  CookRun addLine(CookRunLine line) {
    if (lineOf(line.id) != null) {
      throw StateError('Line ${line.id} exists already.');
    }
    return copyWith(lines: [...lines, line]);
  }

  /// The run without the line [lineId]. The items the line put into the
  /// Vorrat move to [CookRun.droppedItemIds], so finish and discard still
  /// delete them when nobody touched them.
  CookRun removeLine(String lineId) {
    final removed = _require(lineId);
    return copyWith(
      lines: [...lines.where((line) => line.id != lineId)],
      droppedItemIds: [...droppedItemIds, ...removed.addedItemIds],
    );
  }

  /// The run with [line] as it was before it was settled again or removed:
  /// in its old place, or at [index] when [removeLine] took it out. Then the
  /// items it put into the Vorrat leave [CookRun.droppedItemIds] again.
  CookRun restoreLine(CookRunLine line, {required int index}) {
    if (lineOf(line.id) != null) return _line(line.id, (_) => line);
    final dropped = [...droppedItemIds];
    line.addedItemIds.forEach(dropped.remove);
    return copyWith(
      lines: [...lines.take(index), line, ...lines.skip(index)],
      droppedItemIds: dropped,
    );
  }

  /// Back from the shopping: the shopping lines are open again and the run
  /// is on [CookRunStep.assign].
  CookRun reopenShopping() => copyWith(
    step: CookRunStep.assign,
    lines: [
      for (final line in lines)
        if (line.settlement is LineShopping)
          line.copyWith(settlement: const LineOpen())
        else
          line,
    ],
  );

  /// The run cooked with the guide ("Kochhelfer") or without.
  CookRun useGuide({required bool on}) => copyWith(withGuide: on);

  /// The guide on the instruction [index].
  CookRun guideTo(int index) {
    RangeError.checkValidIndex(index, steps, 'index');
    return copyWith(guideStep: index);
  }

  /// The run with [timer] running.
  CookRun addTimer(CookTimer timer) {
    if (timers.any((current) => current.id == timer.id)) {
      throw StateError('Timer ${timer.id} exists already.');
    }
    return copyWith(timers: [...timers, timer]);
  }

  /// The timer [timerId] ending [by] later; one that rang before [now]
  /// rings [by] after [now].
  CookRun extendTimer(String timerId, Duration by, {required DateTime now}) {
    _requireTimer(timerId);
    return copyWith(
      timers: [
        for (final timer in timers)
          if (timer.id == timerId)
            timer.copyWith(
              endsAt: (timer.endsAt.isAfter(now) ? timer.endsAt : now).add(by),
            )
          else
            timer,
      ],
    );
  }

  /// The run without the timer [timerId].
  CookRun stopTimer(String timerId) {
    _requireTimer(timerId);
    return copyWith(timers: [...timers.where((t) => t.id != timerId)]);
  }

  /// The line [lineId] in the pot [potId]. Throws a [StateError] when the
  /// run has no such pot.
  CookRun setPot(String lineId, String potId) {
    final choice = pots;
    if (choice is! CookPotsChosen || !choice.pots.any((p) => p.id == potId)) {
      throw StateError('Pot $potId is not chosen.');
    }
    return _line(lineId, (line) => line.copyWith(potId: () => potId));
  }

  /// The run with [draft] in place of the meal of its pot. Throws an
  /// [ArgumentError] for a count below 1.
  CookRun withMeal(CookMealDraft draft) {
    if (draft.count < 1) {
      throw ArgumentError.value(draft.count, 'count', 'must be at least 1');
    }
    return copyWith(
      meals: [...meals.where((meal) => meal.potId != draft.potId), draft],
    );
  }

  /// Free cooking that does or does not end with a Kochbuch recipe.
  CookRun withToCookbook({required bool on}) => copyWith(toCookbook: on);

  /// The line [lineId] remembering that [itemId] was put into the Vorrat
  /// for it.
  CookRun addedItem(String lineId, String itemId) => _line(
    lineId,
    (line) => line.addedItemIds.contains(itemId)
        ? line
        : line.copyWith(addedItemIds: [...line.addedItemIds, itemId]),
  );

  CookRun _line(String lineId, CookRunLine Function(CookRunLine) change) {
    _require(lineId);
    return copyWith(
      lines: [
        for (final line in lines)
          if (line.id == lineId) change(line) else line,
      ],
    );
  }

  CookRunLine _require(String lineId) {
    final line = lineOf(lineId);
    if (line == null) {
      throw StateError('Line $lineId is gone.');
    }
    return line;
  }

  void _requireTimer(String timerId) {
    if (!timers.any((timer) => timer.id == timerId)) {
      throw StateError('Timer $timerId is gone.');
    }
  }
}
