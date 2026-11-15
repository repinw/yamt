import 'dart:math' show max;

import 'package:yamt/features/inventory/application/ingredient_match_score.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/application/cook_pick_need.dart';
import 'package:yamt/features/kochmodus/domain/cook_food_words.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_line_text.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// What [said] names, an amount in grams or ml (`grams`, they count 1:1; kg
/// and l convert) and a food (`name`), in either order: "30 g Öl", "Öl 30
/// Gramm", "1,5 kg Mehl", "ein Pfund Hack" (see `normalizeCookLineText`).
/// `null` when it names no food, no amount, or one in pieces or spoons
/// ("Salz", "2 EL Öl", "2 Zwiebeln"), or packs of a size that may be a total
/// ("2 Dosen Tomaten 400 g").
({int grams, String name})? parseCookSaidWeight(String said) {
  final parsed = const TemplateIngredientParser().parseRequirement(
    ingredient: said,
    selectedPortions: 1,
    basePortions: 1,
  );
  if (parsed == null ||
      parsed.unit == TemplateIngredientUnit.piece ||
      parsed.packageCountLabel != null ||
      !_namesFood(parsed.name)) {
    return null;
  }
  return (grams: parsed.amount, name: parsed.name);
}

// "30 g" alone leaves the unit as its name, which is no food.
bool _namesFood(String name) => cookFoodWords(name).isNotEmpty;

/// The assigned line of [lines] that the food [name] means, with the Vorrat
/// [items] by id; `null` when none does, so the said text becomes a new line.
/// A line matches when it really is that food (`cookNameIsFood`) by its own
/// name ("Öl" for "2 EL Öl" and "Olivenöl") or by an item it takes from
/// ("Rapsöl" for a line "Öl" with the item Rapsöl). A bundled line ("1 EL Öl,
/// Salz, Pfeffer") is only its first food, because it takes from one item. The
/// best score wins; on a tie the first line still to weigh, else the first
/// line. Names match in the language [localeCode]. A typo of the food
/// ("meis" for "Mais") still finds its line when no line is the food itself.
CookRunLine? cookLineForFood(
  String name, {
  required List<CookRunLine> lines,
  required Map<String, InventoryItem> items,
  required String? localeCode,
}) {
  CookRunLine? best;
  var bestScore = 0;
  var bestToWeigh = false;
  for (final line in lines) {
    if (line.settlement case LineAssigned(:final takes)) {
      final score = _score(name, line, takes, items, localeCode);
      final toWeigh = _toWeigh(line, items);
      if (score > bestScore ||
          (score > 0 && score == bestScore && toWeigh && !bestToWeigh)) {
        best = line;
        bestScore = score;
        bestToWeigh = toWeigh;
      }
    }
  }
  return best;
}

bool _toWeigh(CookRunLine line, Map<String, InventoryItem> items) =>
    switch (cookLineWeightOf(line, items)) {
      CookWeightEstimated() || CookWeightMissing() => true,
      CookWeightExact() ||
      CookWeightWeighed() ||
      CookWeightNotCounted() => false,
    };

// The better of the scores of the line's food and of the items it takes, of
// those that really are the food [name].
int _score(
  String name,
  CookRunLine line,
  List<ItemTake> takes,
  Map<String, InventoryItem> items,
  String? localeCode,
) {
  final food = _firstFood(
    readCookLineText(const TemplateIngredientParser(), line.text)?.name ??
        cookTextForMatch(line.text),
  );
  var best = cookNameIsFood(food, name)
      ? max(
          1,
          ingredientNameMatchScore(
            ingredient: name,
            name: food,
            localeCode: localeCode,
          ),
        )
      : _misspells(name, food)
      ? 1
      : 0;
  // An item that waits with 0 next to a take is not what the line takes from.
  final taking = takes.where((take) => take.amount > 0);
  for (final take in taking.isEmpty ? takes : taking) {
    final item = items[take.itemId];
    if (item == null || !cookNameIsFood(item.name, name)) continue;
    final score = ingredientInventoryMatchScore(
      ingredient: name,
      item: item,
      localeCode: localeCode,
    );
    best = max(best, max(1, score));
  }
  return best;
}

// Whether the last food word of [said] is a typo of a word of [food]: one
// letter off, added or missing, not the first, in words of four letters or
// more ("meis" for "Mais", not "Reis" for "Eis").
bool _misspells(String said, String food) {
  final head = cookFoodWords(said).lastOrNull;
  if (head == null || head.length < 4) return false;
  return cookFoodWords(food).any(
    (word) =>
        word.length >= 4 && word[0] == head[0] && _oneEditApart(head, word),
  );
}

// Whether [a] and [b] differ by one letter changed, added or removed.
bool _oneEditApart(String a, String b) {
  if (a == b || (a.length - b.length).abs() > 1) return false;
  final (short, long) = a.length <= b.length ? (a, b) : (b, a);
  var i = 0;
  while (i < short.length && short[i] == long[i]) {
    i++;
  }
  final rest = short.length == long.length ? i + 1 : i;
  return short.substring(rest) == long.substring(i + 1);
}

// [food] up to its first comma, "oder" or "und": what a bundled line names
// first. A decimal comma stays.
String _firstFood(String food) => food.split(_bundle).first;

final _bundle = RegExp(r',(?!\d)|\s(?:oder|und)\s', caseSensitive: false);
