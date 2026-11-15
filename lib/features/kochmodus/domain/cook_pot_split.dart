import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

/// The lines of [run] by the meal they go into, keyed by [CookPot.id] in
/// the pots' order, or by [countedMealPotId] without a pot. Ignored lines
/// go nowhere. With one pot, or none, every other line is in it; with two
/// or more each line is in its [CookRunLine.potId], else in the first pot.
/// Empty until the cook chose the pots.
Map<String, List<CookRunLine>> cookLinesByPot(CookRun run) {
  final cooked = [
    for (final line in run.lines)
      if (line.settlement is! LineIgnored) line,
  ];
  switch (run.pots) {
    case null:
      return const {};
    case CookCounted():
      return {countedMealPotId: cooked};
    case CookPotsChosen(:final pots):
      final ids = {for (final pot in pots) pot.id};
      final byPot = {for (final pot in pots) pot.id: <CookRunLine>[]};
      for (final line in cooked) {
        final potId = ids.contains(line.potId) ? line.potId! : pots.first.id;
        byPot[potId]!.add(line);
      }
      return byPot;
  }
}
