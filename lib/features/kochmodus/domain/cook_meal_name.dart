import 'package:meta/meta.dart';
import 'package:yamt/features/inventory/domain/cook_line_food.dart';
import 'package:yamt/features/kochmodus/domain/cook_pot_split.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/cook_run_parts.dart';

/// The name a meal of a cook run gets until the cook types another one.
/// The view words it: [CookMealNameInPot] and [CookMealNameWith] join their
/// parts in the app's language, [CookMealNameFree] is "Frei gekocht".
@immutable
sealed class CookMealName {
  /// Creates the name.
  const new();
}

/// A name as it is: the recipe's, or the one food of free cooking.
final class CookMealNamePlain extends CookMealName {
  /// Creates the name.
  const new(this.name);

  /// The name.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is CookMealNamePlain && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

/// The recipe's name with the pot's, for a recipe cooked in two pots or
/// more ("Chili · Großer Topf").
final class CookMealNameInPot extends CookMealName {
  /// Creates the name.
  const new({required this.recipe, required this.pot});

  /// The recipe's name.
  final String recipe;

  /// The pot's name.
  final String pot;

  @override
  bool operator ==(Object other) =>
      other is CookMealNameInPot && other.recipe == recipe && other.pot == pot;

  @override
  int get hashCode => Object.hash(recipe, pot);
}

/// The foods of the first two lines of free cooking ("Reis mit Gemüse").
final class CookMealNameWith extends CookMealName {
  /// Creates the name.
  const new({required this.first, required this.second});

  /// The food of the first line.
  final String first;

  /// The food of the second line.
  final String second;

  @override
  bool operator ==(Object other) =>
      other is CookMealNameWith &&
      other.first == first &&
      other.second == second;

  @override
  int get hashCode => Object.hash(first, second);
}

/// Free cooking without a line ("Frei gekocht").
final class CookMealNameFree extends CookMealName {
  /// Creates the name.
  const new();

  @override
  bool operator ==(Object other) => other is CookMealNameFree;

  @override
  int get hashCode => (CookMealNameFree).hashCode;
}

/// The name of the meal in the pot [potId] of [run] (a [CookPot.id] or
/// [countedMealPotId]). A recipe gives its name, with the pot's name when
/// two pots or more hold meals and the pot has one. Free cooking names the
/// foods of the first two lines in that pot.
CookMealName cookMealName(CookRun run, String potId) {
  switch (run.kind) {
    case CookRunKind.recipe:
      final pot = switch (run.pots) {
        CookPotsChosen(:final pots) when pots.length > 1 =>
          pots.where((pot) => pot.id == potId).firstOrNull,
        _ => null,
      };
      final potName = pot?.name?.trim() ?? '';
      return potName.isEmpty
          ? CookMealNamePlain(run.name)
          : CookMealNameInPot(recipe: run.name, pot: potName);
    case CookRunKind.free:
      final foods = [
        for (final line in cookLinesByPot(run)[potId] ?? const <CookRunLine>[])
          if (cookLineFood(line.text) case final food when food.isNotEmpty)
            food,
      ];
      return switch (foods) {
        [] => const CookMealNameFree(),
        [final food] => CookMealNamePlain(food),
        [final first, final second, ...] => CookMealNameWith(
          first: first,
          second: second,
        ),
      };
  }
}
